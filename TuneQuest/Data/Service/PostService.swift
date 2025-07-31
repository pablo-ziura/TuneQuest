import Foundation
import TuneNetwork

final class PostService: PostServiceProtocol {
    private let client: NetworkClientProtocol

    init(client: NetworkClientProtocol) {
        self.client = client
    }

    func fetchPosts() async throws -> [PostDTO] {
        try await client.get(
            endpoint: "posts",
            params: nil,
            headers: nil
        )
    }
}
