import Foundation
import Testing
import TuneNetwork
@testable import TuneQuest

@Suite("TrackService")
struct TrackServiceTests {
    @Test("returns metadata even when the requested track has no preview")
    func trackWithoutPreview() async throws {
        let service = TrackService(client: StubClient(json: #"{"id":1,"title":"Track"}"#))

        let result = try await service.fetchTrack(id: 1)

        #expect(result.id == 1)
        #expect(result.title == "Track")
        #expect(result.preview == nil)
    }

    @Test("rejects an API error or a different track instead of showing empty metadata", arguments: [
        #"{"error":{"type":"DataException","message":"no data","code":800}}"#,
        #"{"id":2,"title":"Another track"}"#
    ])
    func invalidResponse(json: String) async {
        let service = TrackService(client: StubClient(json: json))

        await #expect(throws: TrackServiceError.self) {
            try await service.fetchTrack(id: 1)
        }
    }

    private struct StubClient: NetworkClientProtocol {
        let json: String

        func get<O: Decodable>(endpoint: String, params: [String: String]?, headers: [String: String]?) async throws -> O {
            try JSONDecoder().decode(O.self, from: Data(json.utf8))
        }

        func post<O: Decodable>(endpoint: String, params: [String: String]?, headers: [String: String]?, body: Data) async throws -> O {
            throw URLError(.unsupportedURL)
        }
    }
}
