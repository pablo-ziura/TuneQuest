import Foundation

struct Post: Codable, Equatable, Hashable, Sendable {
    let id: Int
    let authorId: Int
    let title: String
    let content: String
}

extension Post {
    init(dto: PostDTO) {
        id = dto.id
        authorId = dto.userId
        title = dto.title
        content = dto.body
    }
}
