import Foundation

protocol PostRepositoryProtocol: Sendable {
    func posts() async throws -> [Post]

}
