import Foundation

enum CatalogDataSourceError: Error {
    case fileNotFound
}

final class CatalogLocalDataSource: CatalogDataSourceProtocol {
    private let loader: @Sendable () throws -> Data

    init(loader: @escaping @Sendable () throws -> Data = {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json") else {
            throw CatalogDataSourceError.fileNotFound
        }
        return try Data(contentsOf: url)
    }) {
        self.loader = loader
    }

    func fetchCatalog() async throws -> CatalogDTO {
        let data = try loader()
        return try JSONDecoder().decode(CatalogDTO.self, from: data)
    }
}
