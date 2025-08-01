import Foundation
import SwiftUI
import TuneNetwork

@MainActor
@Observable
final class DependencyContainer {
    static let shared = DependencyContainer()

    let router: Router
    let networkClient: NetworkClientProtocol
    let postService: PostServiceProtocol
    let postRepository: PostRepositoryProtocol
    let getPostsUseCase: GetPostsUseCase
    let postsViewModel: PostsViewModel
    let previewPlayerManager: PreviewPlayerManager

    private init() {
        guard let baseUrl = Bundle.main.infoDictionary?["BASE_URL"] as? String else {
            fatalError("Entry not found for BASE_URL")
        }

        router = Router()

        func makeNetworkClient() -> NetworkClientProtocol {
            NetworkClient(baseUrl: baseUrl)
        }

        func makePostService(client: NetworkClientProtocol) -> PostServiceProtocol {
            PostService(client: client)
        }

        func makePostRepository(service: PostServiceProtocol) -> PostRepositoryProtocol {
            PostRepository(service: service)
        }

        let client = makeNetworkClient()
        networkClient = client

        let service = makePostService(client: client)
        postService = service

        let repository = makePostRepository(service: service)
        postRepository = repository

        getPostsUseCase = GetPostsUseCase(repository: repository)
        postsViewModel = PostsViewModel(getPostsUseCase: getPostsUseCase)

        previewPlayerManager = PreviewPlayerManager()
    }
}
