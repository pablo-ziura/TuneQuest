import Foundation

enum CatalogDataSourceError: Error {
    case fileNotFound
}

final class CatalogLocalDataSource: CatalogDataSourceProtocol {
    func fetchCatalog() async throws -> CatalogDTO {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json") else {
            throw CatalogDataSourceError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(CatalogDTO.self, from: data)
    }
}
