import Foundation
@testable import TuneQuest

final actor MockTrackService: TrackServiceProtocol, @unchecked Sendable {
    var result: Result<TrackDTO, Error>

    init(result: Result<TrackDTO, Error>) {
        self.result = result
    }

    func fetchTrack(id: Int) async throws -> TrackDTO {
        switch result {
        case let .success(value):
            return value
        case let .failure(error):
            throw error
        }
    }
}
