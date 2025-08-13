import Foundation

struct Catalog: Equatable, Hashable, Sendable {
    let ids: [Int]
}

extension Catalog {
    init(dto: CatalogDTO) {
        self.ids = dto.ids.compactMap { Int($0) }
    }
}
