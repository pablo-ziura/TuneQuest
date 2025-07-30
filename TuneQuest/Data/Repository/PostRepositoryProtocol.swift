import Foundation

protocol PostRepositoryProtocol: Sendable {
    func posts() async throws -> [PostDTO]
}
