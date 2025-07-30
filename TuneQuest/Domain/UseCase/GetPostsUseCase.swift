import Foundation

struct GetPostsUseCase {
    private let repository: PostRepositoryProtocol

    init(repository: PostRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> [PostDTO] {
        try await repository.posts()
    }
}
