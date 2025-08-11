import Foundation

enum CatalogServiceError: Error {
    case fileNotFound
}

final class CatalogService: CatalogServiceProtocol {
    func fetchCatalog() async throws -> CatalogDTO {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json") else {
            throw CatalogServiceError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(CatalogDTO.self, from: data)
    }
}
