import Foundation
@testable import TuneQuest

final actor MockCatalogDataSource: CatalogDataSourceProtocol, @unchecked Sendable {
    var result: Result<CatalogDTO, Error>

    init(result: Result<CatalogDTO, Error>) {
        self.result = result
    }

    func fetchCatalog() async throws -> CatalogDTO {
        switch result {
        case let .success(value):
            return value
        case let .failure(error):
            throw error
        }
    }
}
