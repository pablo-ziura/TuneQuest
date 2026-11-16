import SwiftUI
import OSLog

@MainActor
@Observable
final class CatalogViewModel {
    private let getCatalogUseCase: GetCatalogUseCase
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TuneQuest", category: "Catalog")
    private var loadID = UUID()

    private(set) var catalog: Catalog?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(getCatalogUseCase: GetCatalogUseCase) {
        self.getCatalogUseCase = getCatalogUseCase
    }

    func fetchData() async {
        guard !Task.isCancelled else { return }
        let id = UUID()
        loadID = id
        isLoading = true
        catalog = nil
        errorMessage = nil
        defer {
            if loadID == id { isLoading = false }
        }

        do {
            let result = try await getCatalogUseCase.execute()
            try Task.checkCancellation()
            guard loadID == id else { return }
            catalog = result
        } catch {
            guard loadID == id, !Task.isCancelled, !(error is CancellationError) else { return }
            errorMessage = "The catalog could not be loaded. Please try again."
            logger.error("Error: \(error.localizedDescription, privacy: .public)")
        }
    }

    func cancelLoading() {
        loadID = UUID()
        catalog = nil
        isLoading = false
        errorMessage = nil
    }
}
