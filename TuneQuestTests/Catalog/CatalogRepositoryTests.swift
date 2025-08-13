import Foundation
import Testing
@testable import TuneQuest

@Suite("CatalogRepository")
final class CatalogRepositoryTests: @unchecked Sendable {
    @Test("fetchCatalog maps DTO to domain model")
    func fetchCatalogSuccess() async throws {
        let dto = CatalogDTO(version: 1, modified: "2025-08-11", ids: [1, 2])
        let dataSource = MockCatalogDataSource(result: .success(dto))
        let sut = CatalogRepository(dataSource: dataSource)

        let result = try await sut.fetchCatalog()
        #expect(result == Catalog(ids: [1, 2]))
    }

    @Test("fetchCatalog propagates errors")
    func fetchCatalogFailure() async {
        enum SampleError: Error { case fail }
        let dataSource = MockCatalogDataSource(result: .failure(SampleError.fail))
        let sut = CatalogRepository(dataSource: dataSource)

        var thrown: Error?
        do {
            _ = try await sut.fetchCatalog()
        } catch {
            thrown = error
        }
        #expect(thrown != nil)
    }
}
