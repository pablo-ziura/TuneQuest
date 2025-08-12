import Foundation
import Testing
@testable import TuneQuest

@MainActor
@Suite("GetTrackPreviewUseCase")
final class GetTrackPreviewUseCaseTests: @unchecked Sendable {
    @Test("execute returns repository track")
    func executeSuccess() async throws {
        let track = Track(url: URL(string: "https://example.com/track.mp3")!)
        let repo = MockTrackRepository(result: .success(track))
        let sut = GetTrackPreviewUseCase(repository: repo)

        let result = try await sut.execute(trackId: 1)
        #expect(result == track)
    }

    @Test("execute propagates errors")
    func executeFailure() async {
        enum SampleError: Error { case fail }
        let repo = MockTrackRepository(result: .failure(SampleError.fail))
        let sut = GetTrackPreviewUseCase(repository: repo)

        var thrown: Error?
        do {
            _ = try await sut.execute(trackId: 1)
        } catch {
            thrown = error
        }
        #expect(thrown != nil)
    }
}
