import Foundation
import Testing
@testable import TuneQuest

@MainActor
@Suite("GetCatalogUseCase")
final class GetCatalogUseCaseTests: @unchecked Sendable {
    @Test("execute returns repository catalog")
    func executeSuccess() async throws {
        let catalog = Catalog(ids: [1, 2])
        let repo = MockCatalogRepository(result: .success(catalog))
        let sut = GetCatalogUseCase(repository: repo)

        let result = try await sut.execute()
        #expect(result == catalog)
    }

    @Test("execute propagates errors")
    func executeFailure() async {
        enum SampleError: Error { case fail }
        let repo = MockCatalogRepository(result: .failure(SampleError.fail))
        let sut = GetCatalogUseCase(repository: repo)

        var thrown: Error?
        do {
            _ = try await sut.execute()
        } catch {
            thrown = error
        }
        #expect(thrown != nil)
    }
}
