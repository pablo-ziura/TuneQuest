import Foundation

final class CatalogRepository: CatalogRepositoryProtocol {
    private let dataSource: CatalogDataSourceProtocol

    init(dataSource: CatalogDataSourceProtocol) {
        self.dataSource = dataSource
    }

    func fetchCatalog() async throws -> Catalog {
        let dto = try await dataSource.fetchCatalog()
        return Catalog(dto: dto)
    }
}
