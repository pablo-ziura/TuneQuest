import Foundation
import Testing
@testable import TuneQuest

@Suite("CatalogLocalDataSource")
final class CatalogLocalDataSourceTests: @unchecked Sendable {
    @Test("fetchCatalog returns decoded DTO")
    func fetchCatalogSuccess() async throws {
        let json =
            """
            {
            "version":1,
            "modified":"2025-08-11",
            "ids":[1,2]
            }
            """
            .data(using: .utf8)!
        let sut = CatalogLocalDataSource(loader: { json })

        let result = try await sut.fetchCatalog()
        #expect(result == CatalogDTO(version: 1, modified: "2025-08-11", ids: [1, 2]))
    }

    @Test("fetchCatalog propagates errors")
    func fetchCatalogFailure() async {
        enum SampleError: Error { case fail }
        let sut = CatalogLocalDataSource(loader: { throw SampleError.fail })

        var thrown: Error?
        do {
            _ = try await sut.fetchCatalog()
        } catch {
            thrown = error
        }
        #expect(thrown != nil)
    }
}
