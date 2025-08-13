import Foundation
import Testing
@testable import TuneQuest

@Suite("TrackRepository")
final class TrackRepositoryTests: @unchecked Sendable {
    @Test("preview maps DTO to domain model")
    func previewSuccess() async throws {
        let dto = TrackDTO(preview: "https://example.com/track.mp3")
        let service = MockTrackService(result: .success(dto))
        let sut = TrackRepository(service: service)

        let result = try await sut.preview(for: 1)
        #expect(result == Track(dto: dto))
    }

    @Test("preview propagates errors")
    func previewFailure() async {
        enum SampleError: Error { case fail }
        let service = MockTrackService(result: .failure(SampleError.fail))
        let sut = TrackRepository(service: service)

        var thrown: Error?
        do {
            _ = try await sut.preview(for: 1)
        } catch {
            thrown = error
        }
        #expect(thrown != nil)
    }
}
