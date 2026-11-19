import Foundation
import TuneNetwork

enum TrackServiceError: Error {
    case trackUnavailable
}

final class TrackService: TrackServiceProtocol {
    private let client: NetworkClientProtocol

    init(client: NetworkClientProtocol) {
        self.client = client
    }

    func fetchTrack(id: Int) async throws -> TrackDTO {
        let track: TrackDTO = try await client.get(endpoint: "track/\(id)", params: nil, headers: nil)
        // Deezer may return an error payload with HTTP 200. All DTO fields are optional.
        guard track.id == id else { throw TrackServiceError.trackUnavailable }
        return track
    }
}
