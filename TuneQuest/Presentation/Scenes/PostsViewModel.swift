import SwiftUI
import OSLog

@MainActor
@Observable
final class PostsViewModel {
    let getPostsUseCase: GetPostsUseCase
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "PostsViewModel", category: "Presentation")

    var posts: [Post] = []

    var isLoading = false

    init(getPostsUseCase: GetPostsUseCase) {
        self.getPostsUseCase = getPostsUseCase
    }

    public func fetchData() async {
        isLoading = true
        defer { isLoading = false }
        await self.getPosts()
    }

    private func getPosts() async {
        do {
            posts = try await getPostsUseCase.execute()
        } catch {
            logger.error("Error: \(error.localizedDescription, privacy: .public)")
        }
    }
}
