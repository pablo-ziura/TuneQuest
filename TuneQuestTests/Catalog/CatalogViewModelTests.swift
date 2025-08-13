import Foundation
import Testing
@testable import TuneQuest

@MainActor
@Suite("CatalogViewModel")
final class CatalogViewModelTests: @unchecked Sendable {
    @Test("fetchData populates catalog and toggles loading")
    func fetchDataSuccess() async throws {
        let catalog = Catalog(ids: [1, 2])
        let repo = MockCatalogRepository(result: .success(catalog))
        let useCase = GetCatalogUseCase(repository: repo)
        let vm = CatalogViewModel(getCatalogUseCase: useCase)

        await vm.fetchData()
        try await Task.sleep(nanoseconds: 10000000)

        #expect(vm.catalog == catalog)
        #expect(vm.isLoading == false)
    }

    @Test("fetchData handles errors")
    func fetchDataFailure() async throws {
        enum SampleError: Error { case fail }
        let repo = MockCatalogRepository(result: .failure(SampleError.fail))
        let useCase = GetCatalogUseCase(repository: repo)
        let vm = CatalogViewModel(getCatalogUseCase: useCase)

        await vm.fetchData()
        try await Task.sleep(nanoseconds: 10000000)

        #expect(vm.catalog == nil)
        #expect(vm.isLoading == false)
    }
}
