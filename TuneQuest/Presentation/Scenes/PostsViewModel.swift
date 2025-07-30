import SwiftUI

@MainActor
@Observable
final class PostsViewModel {
    let getPostsUseCase: GetPostsUseCase

    var posts: [PostDTO] = []

    var isLoading = false

    private var fetchTask: Task<Void, Never>?

    init(getPostsUseCase: GetPostsUseCase) {
        self.getPostsUseCase = getPostsUseCase
    }

    public func fetchData() {
        fetchTask?.cancel()
        fetchTask = Task {
            isLoading = true
            defer { isLoading = false }
            await self.getPosts()
        }
    }

    private func getPosts() async {
        do {
            posts = try await getPostsUseCase.execute()
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}
