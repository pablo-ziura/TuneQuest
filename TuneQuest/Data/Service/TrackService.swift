import Foundation
import TuneNetwork

final class TrackService: TrackServiceProtocol {
    private let client: NetworkClientProtocol

    init(client: NetworkClientProtocol) {
        self.client = client
    }

    func fetchTrack(id: Int) async throws -> TrackDTO {
        try await client.get(endpoint: "track/\(id)", params: nil, headers: nil)
    }
}
