import Foundation

protocol CatalogDataSourceProtocol: Sendable {
    func fetchCatalog() async throws -> CatalogDTO
}
