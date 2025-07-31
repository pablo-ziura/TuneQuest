import Foundation
import Testing
@testable import TuneNetwork
@testable import TuneQuest

@MainActor
@Suite("PostService")
final class PostServiceTests: @unchecked Sendable {
    @Test("fetchPosts passes correct endpoint and returns value")
    func fetchPostsSuccess() async throws {
        let expected = [PostDTO(userId: 1, id: 1, title: "T", body: "B")]
        let client = MockNetworkClient(result: .success(expected))
        let sut = PostService(client: client)

        let result = try await sut.fetchPosts()
        #expect(await client.getCalledWith == "posts")
        #expect(result == expected)
    }

    @Test("fetchPosts propagates errors")
    func fetchPostsFailure() async {
        enum SampleError: Error { case fail }
        let client = MockNetworkClient(result: .failure(SampleError.fail))
        let sut = PostService(client: client)

        var thrown: Error?
        do {
            _ = try await sut.fetchPosts()
        } catch {
            thrown = error
        }
        #expect(thrown != nil)
    }
}
