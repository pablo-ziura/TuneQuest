import Foundation
@testable import TuneQuest

/// Each request can finish independently, including after cancellation.
actor SuspendedTrackRepository: TrackRepositoryProtocol {
    private var pending: [Int: CheckedContinuation<Track, Never>] = [:]
    private var requestWaiters: [Int: CheckedContinuation<Void, Never>] = [:]

    func preview(for trackId: Int) async throws -> Track {
        await withCheckedContinuation { continuation in
            pending[trackId] = continuation
            requestWaiters.removeValue(forKey: trackId)?.resume()
        }
    }

    func waitUntilRequested(_ trackId: Int) async {
        guard pending[trackId] == nil else { return }
        await withCheckedContinuation { requestWaiters[trackId] = $0 }
    }

    func complete(_ trackId: Int, with track: Track) {
        pending.removeValue(forKey: trackId)?.resume(returning: track)
    }
}
