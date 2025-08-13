import Foundation
@testable import TuneQuest

final actor MockTrackRepository: TrackRepositoryProtocol, @unchecked Sendable {
    var result: Result<Track, Error>

    init(result: Result<Track, Error>) {
        self.result = result
    }

    func preview(for trackId: Int) async throws -> Track {
        switch result {
        case let .success(value):
            return value
        case let .failure(error):
            throw error
        }
    }
}
