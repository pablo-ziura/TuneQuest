import SwiftUI
import OSLog

@MainActor
@Observable
final class CatalogViewModel {
    let getCatalogUseCase: GetCatalogUseCase
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "PostsViewModel", category: "Presentation")

    var catalog: Catalog?

    var isLoading = false

    init(getCatalogUseCase: GetCatalogUseCase) {
        self.getCatalogUseCase = getCatalogUseCase
    }

    public func fetchData() async {
        isLoading = true
        defer { isLoading = false }
        await self.getCatalog()
    }

    private func getCatalog() async {
        do {
            catalog = try await getCatalogUseCase.execute()
        } catch {
            logger.error("Error: \(error.localizedDescription, privacy: .public)")
        }
    }
}
