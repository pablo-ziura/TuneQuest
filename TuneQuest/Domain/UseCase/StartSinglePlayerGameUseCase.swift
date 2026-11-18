import Foundation

struct StartSinglePlayerGameUseCase {
    private let repository: CatalogRepositoryProtocol
    private let configuration: GameConfiguration
    private let shuffle: @Sendable ([CatalogEntry]) -> [CatalogEntry]

    init(repository: CatalogRepositoryProtocol, configuration: GameConfiguration = .init(),
         shuffle: @escaping @Sendable ([CatalogEntry]) -> [CatalogEntry] = { $0.shuffled() }) {
        self.repository = repository
        self.configuration = configuration
        self.shuffle = shuffle
    }

    func execute() async throws -> GameSession {
        let catalog = try await repository.fetchCatalog()
        try Task.checkCancellation()
        let currentYear = Calendar.current.component(.year, from: Date())
        guard Set(catalog.entries.map(\.id)).count == catalog.entries.count,
              catalog.entries.allSatisfy({
                  $0.id > 0 && !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                      && !$0.artist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                      && (1900...currentYear).contains($0.originalReleaseYear)
                      && $0.releaseYearSource.scheme == "https" && $0.releaseYearSource.host != nil
              }) else {
            throw GameSessionError.invalidCatalog
        }
        return try GameSession(tracks: shuffle(catalog.entries), configuration: configuration)
    }
}
