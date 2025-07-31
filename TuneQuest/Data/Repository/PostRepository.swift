import Foundation

final class PostRepository: PostRepositoryProtocol {
    private let service: PostServiceProtocol

    init(service: PostServiceProtocol) {
        self.service = service
    }

    func posts() async throws -> [Post] {
        let dtos = try await service.fetchPosts()
        return dtos.map(Post.init(dto:))
    }}
