import Foundation
@testable import TuneQuest

/// Allows overlapping loads to complete in any order, even after cancellation.
actor SequencedCatalogRepository: CatalogRepositoryProtocol {
    private var count = 0
    private var pending: [Int: CheckedContinuation<Catalog, Never>] = [:]
    private var waiters: [(Int, CheckedContinuation<Void, Never>)] = []

    func fetchCatalog() async throws -> Catalog {
        count += 1
        let request = count
        return await withCheckedContinuation { continuation in
            pending[request] = continuation
            for (target, waiter) in waiters where target <= count { waiter.resume() }
            waiters.removeAll { $0.0 <= count }
        }
    }

    func waitUntilRequested(_ target: Int) async {
        guard count < target else { return }
        await withCheckedContinuation { waiters.append((target, $0)) }
    }

    func complete(_ request: Int, with catalog: Catalog) {
        pending.removeValue(forKey: request)?.resume(returning: catalog)
    }
}
