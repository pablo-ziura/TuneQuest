import Foundation

struct Catalog: Equatable, Hashable, Sendable {
    let entries: [CatalogEntry]

    var ids: [Int] { entries.map(\.id) }
}

extension Catalog {
    init(dto: CatalogDTO) {
        entries = dto.entries.map {
            CatalogEntry(id: $0.id, title: $0.title, artist: $0.artist,
                         originalReleaseYear: $0.originalReleaseYear, releaseYearSource: $0.releaseYearSource)
        }
    }
}
