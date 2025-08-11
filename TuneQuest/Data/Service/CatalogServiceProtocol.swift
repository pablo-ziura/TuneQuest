import Foundation

protocol CatalogServiceProtocol: Sendable {
    func fetchCatalog() async throws -> CatalogDTO
}
