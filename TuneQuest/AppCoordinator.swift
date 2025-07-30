import Foundation
import SwiftUI
import TuneNetwork

@MainActor
@Observable
final class AppCoordinator {
    private let networkClient: NetworkClientProtocol
    private let postsViewModel: PostsViewModel

    init() {
        guard let baseUrl = Bundle.main.infoDictionary?["BASE_URL"] as? String else {
            fatalError("Entry not found for BASE_URL")
        }

        networkClient = NetworkClient(baseUrl: baseUrl)

        let service = PostService(client: networkClient)
        let repository = PostRepository(service: service)
        let getPostsUseCase = GetPostsUseCase(repository: repository)

        postsViewModel = PostsViewModel(getPostsUseCase: getPostsUseCase)

    }

    func getContentView() -> some View {
        ContentView()
            .environment(self)
    }

    func getPostsView() -> some View {
        PostsView()
            .environment(self)
            .environment(postsViewModel)
    }
}
