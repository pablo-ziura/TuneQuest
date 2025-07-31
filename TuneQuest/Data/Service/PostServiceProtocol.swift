import Foundation

protocol PostServiceProtocol: Sendable {
    func fetchPosts() async throws -> [PostDTO]
}
