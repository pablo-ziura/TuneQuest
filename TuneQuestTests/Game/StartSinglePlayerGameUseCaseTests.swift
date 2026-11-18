import Foundation
import Testing
@testable import TuneQuest

@Suite("StartSinglePlayerGameUseCase")
struct StartSinglePlayerGameUseCaseTests {
    @Test("a shuffled catalog supplies eleven unique songs and ten guesses")
    func prepareGame() async throws {
        let entries = (1...20).map { gameEntry($0) }
        let repository = MockCatalogRepository(result: .success(Catalog(entries: entries)))
        let game = try await StartSinglePlayerGameUseCase(repository: repository, shuffle: { $0.reversed() }).execute()
        #expect(game.timeline.map(\.id) == [20])
        #expect(game.pendingTrack.id == 19)
        #expect(game.remainingLives == 3)
        var completed = game
        var usedIDs = Set(completed.timeline.map(\.id))
        for _ in 0..<10 {
            #expect(usedIDs.insert(completed.pendingTrack.id).inserted)
            completed.confirm(at: completed.timeline.count)
            completed.advance()
        }
        #expect(completed.phase == .won)
        #expect(usedIDs.count == 11)
    }

    @Test("duplicates, missing metadata and invalid years reject the catalog")
    func invalidEntries() async {
        let invalid = [gameEntry(0), gameEntry(1, year: 0), gameEntry(1, year: 9999),
                       CatalogEntry(id: 1, title: " ", artist: "Artist", originalReleaseYear: 2000,
                                    releaseYearSource: URL(string: "https://example.com")!)]
        for entry in invalid {
            let repo = MockCatalogRepository(result: .success(Catalog(entries: [entry])))
            await #expect(throws: GameSessionError.invalidCatalog) {
                try await StartSinglePlayerGameUseCase(repository: repo).execute()
            }
        }
        let repo = MockCatalogRepository(result: .success(Catalog(entries: [gameEntry(1), gameEntry(1)])))
        await #expect(throws: GameSessionError.invalidCatalog) {
            try await StartSinglePlayerGameUseCase(repository: repo).execute()
        }
    }

    @Test("too few songs and repository failures are propagated")
    func loadingFailures() async {
        let repo = MockCatalogRepository(result: .success(Catalog(entries: [gameEntry(1)])))
        await #expect(throws: GameSessionError.insufficientTracks) {
            try await StartSinglePlayerGameUseCase(repository: repo).execute()
        }
        await repo.setResult(.failure(CatalogDataSourceError.fileNotFound))
        await #expect(throws: CatalogDataSourceError.self) {
            try await StartSinglePlayerGameUseCase(repository: repo).execute()
        }
    }
}
