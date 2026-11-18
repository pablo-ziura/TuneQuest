import Foundation

struct CatalogDTO: Codable, Equatable, Hashable, Sendable {
    let version: Int
    let modified: String
    let entries: [CatalogEntryDTO]
}

struct CatalogEntryDTO: Codable, Equatable, Hashable, Sendable {
    let id: Int
    let title: String
    let artist: String
    let originalReleaseYear: Int
    let releaseYearSource: URL
}
