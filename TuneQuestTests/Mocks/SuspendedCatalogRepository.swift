import Foundation
@testable import TuneQuest

/// Deliberately ignores task cancellation to exercise stale-response protection.
actor SuspendedCatalogRepository: CatalogRepositoryProtocol {
    private var pending: CheckedContinuation<Catalog, Never>?
    private var requestWaiter: CheckedContinuation<Void, Never>?

    func fetchCatalog() async throws -> Catalog {
        await withCheckedContinuation { continuation in
            pending = continuation
            requestWaiter?.resume()
            requestWaiter = nil
        }
    }

    func waitUntilRequested() async {
        guard pending == nil else { return }
        await withCheckedContinuation { requestWaiter = $0 }
    }

    func complete(with catalog: Catalog) {
        pending?.resume(returning: catalog)
        pending = nil
    }
}
