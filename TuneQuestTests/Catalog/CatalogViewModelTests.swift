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
        #expect(vm.catalog == catalog)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
    }

    @Test("fetchData handles errors")
    func fetchDataFailure() async throws {
        enum SampleError: Error { case fail }
        let repo = MockCatalogRepository(result: .failure(SampleError.fail))
        let useCase = GetCatalogUseCase(repository: repo)
        let vm = CatalogViewModel(getCatalogUseCase: useCase)

        await vm.fetchData()
        #expect(vm.catalog == nil)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage != nil)
    }

    @Test("retry clears the error and accepts an empty catalog")
    func retryAfterFailure() async {
        let repo = MockCatalogRepository(result: .failure(CatalogDataSourceError.fileNotFound))
        let vm = CatalogViewModel(getCatalogUseCase: GetCatalogUseCase(repository: repo))
        await vm.fetchData()
        #expect(vm.errorMessage != nil)

        await repo.setResult(.success(Catalog(ids: [])))
        await vm.fetchData()

        #expect(vm.catalog == Catalog(ids: []))
        #expect(vm.errorMessage == nil)
        #expect(!vm.isLoading)
    }

    @Test("leaving the screen discards a late catalog response")
    func discardsLateResponse() async {
        let repo = SuspendedCatalogRepository()
        let vm = CatalogViewModel(getCatalogUseCase: GetCatalogUseCase(repository: repo))
        let task = Task { await vm.fetchData() }
        await repo.waitUntilRequested()
        #expect(vm.isLoading)

        vm.cancelLoading()
        await repo.complete(with: Catalog(ids: [1]))
        await task.value

        #expect(vm.catalog == nil)
        #expect(vm.errorMessage == nil)
        #expect(!vm.isLoading)
    }

    @Test("cancelling a load does not display an error")
    func cancellationIsSilent() async {
        let repo = SuspendedCatalogRepository()
        let vm = CatalogViewModel(getCatalogUseCase: GetCatalogUseCase(repository: repo))
        let task = Task { await vm.fetchData() }
        await repo.waitUntilRequested()
        task.cancel()
        await repo.complete(with: Catalog(ids: [1]))
        await task.value

        #expect(vm.catalog == nil)
        #expect(vm.errorMessage == nil)
        #expect(!vm.isLoading)
    }
}
