import Foundation

final class PostRepository: PostRepositoryProtocol {
    private let service: PostServiceProtocol

    init(service: PostServiceProtocol) {
        self.service = service
    }

    func posts() async throws -> [PostDTO] {
        try await service.fetchPosts()
    }
}
