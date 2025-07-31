import Foundation
import Testing
@testable import TuneQuest

@MainActor
@Suite("GetPostsUseCase")
final class GetPostsUseCaseTests: @unchecked Sendable {
    @Test("execute returns repository posts")
    func executeSuccess() async throws {
        let post = Post(id: 1, authorId: 2, title: "A", content: "B")
        let repo = MockPostRepository(result: .success([post]))
        let sut = GetPostsUseCase(repository: repo)

        let result = try await sut.execute()
        #expect(result == [post])
    }

    @Test("execute propagates errors")
    func executeFailure() async {
        enum SampleError: Error { case fail }
        let repo = MockPostRepository(result: .failure(SampleError.fail))
        let sut = GetPostsUseCase(repository: repo)

        var thrown: Error?
        do {
            _ = try await sut.execute()
        } catch {
            thrown = error
        }
        #expect(thrown != nil)
    }
}
