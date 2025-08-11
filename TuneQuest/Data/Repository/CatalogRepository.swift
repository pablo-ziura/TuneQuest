import Foundation

final class CatalogRepository: CatalogRepositoryProtocol {
    private let service: CatalogServiceProtocol

    init(service: CatalogServiceProtocol) {
        self.service = service
    }

    func fetchCatalog() async throws -> Catalog {
        let dto = try await service.fetchCatalog()
        return Catalog(dto: dto)
    }
}
