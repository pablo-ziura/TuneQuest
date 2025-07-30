import Foundation

struct PostDTO: Codable, Equatable, Hashable, Sendable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}
