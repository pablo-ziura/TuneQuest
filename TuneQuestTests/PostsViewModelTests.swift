import Foundation
import Testing
@testable import TuneQuest

@MainActor
@Suite("PostsViewModel")
final class PostsViewModelTests: @unchecked Sendable {
    @Test("fetchData populates posts and toggles loading")
    func fetchDataSuccess() async throws {
        let post = Post(id: 1, authorId: 1, title: "T", content: "C")
        let repo = MockPostRepository(result: .success([post]))
        let useCase = GetPostsUseCase(repository: repo)
        let vm = PostsViewModel(getPostsUseCase: useCase)

        await vm.fetchData()
        try await Task.sleep(nanoseconds: 10000000)

        #expect(vm.posts == [post])
        #expect(vm.isLoading == false)
    }

    @Test("fetchData handles errors")
    func fetchDataFailure() async throws {
        enum SampleError: Error { case fail }
        let repo = MockPostRepository(result: .failure(SampleError.fail))
        let useCase = GetPostsUseCase(repository: repo)
        let vm = PostsViewModel(getPostsUseCase: useCase)

        await vm.fetchData()
        try await Task.sleep(nanoseconds: 10000000)

        #expect(vm.posts.isEmpty)
        #expect(vm.isLoading == false)
    }
}
