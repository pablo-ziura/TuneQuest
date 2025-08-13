import Foundation

protocol CatalogRepositoryProtocol: Sendable {
    func fetchCatalog() async throws -> Catalog
}
