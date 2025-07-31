import Foundation
import Testing
@testable import TuneQuest

@Suite("PostRepository")
final class PostRepositoryTests: @unchecked Sendable {
    @Test("posts maps DTOs to domain models")
    func postsSuccess() async throws {
        let dto = PostDTO(userId: 1, id: 2, title: "Title", body: "Body")
        let expected = Post(dto: dto)
        let service = MockPostService(result: .success([dto]))
        let sut = PostRepository(service: service)

        let result = try await sut.posts()
        #expect(result == [expected])
    }

    @Test("posts propagates errors")
    func postsFailure() async {
        enum SampleError: Error { case fail }
        let service = MockPostService(result: .failure(SampleError.fail))
        let sut = PostRepository(service: service)

        var thrown: Error?
        do {
            _ = try await sut.posts()
        } catch {
            thrown = error
        }
        #expect(thrown != nil)
    }
}
