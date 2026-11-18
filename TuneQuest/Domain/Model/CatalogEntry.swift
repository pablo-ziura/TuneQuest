import Foundation

struct CatalogEntry: Identifiable, Equatable, Hashable, Sendable {
    let id: Int
    let title: String
    let artist: String
    let originalReleaseYear: Int
    let releaseYearSource: URL
}
