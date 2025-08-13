import Foundation

struct CatalogDTO: Codable, Equatable, Hashable, Sendable {
    let version: Int
    let modified: String
    let ids: [Int]
}
