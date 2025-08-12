import Foundation
import SwiftUI
import TuneNetwork

@MainActor
@Observable
final class DependencyContainer {
    static let shared = DependencyContainer()

    let router: Router
    let networkClient: NetworkClientProtocol
    let trackService: TrackServiceProtocol
    let trackRepository: TrackRepositoryProtocol
    let getTrackPreviewUseCase: GetTrackPreviewUseCase
    let catalogDataSource: CatalogDataSourceProtocol
    let catalogRepository: CatalogRepositoryProtocol
    let getCatalogUseCase: GetCatalogUseCase
    let catalogViewModel: CatalogViewModel
    let audioPlayerManager: AudioPlayerManager

    private init() {
        guard let baseUrl = Bundle.main.infoDictionary?["BASE_URL"] as? String else {
            fatalError("Entry not found for BASE_URL")
        }

        router = Router()

        func makeNetworkClient() -> NetworkClientProtocol {
            NetworkClient(baseUrl: baseUrl)
        }

        func makeTrackService(client: NetworkClientProtocol) -> TrackServiceProtocol {
            TrackService(client: client)
        }

        func makeTrackRepository(service: TrackServiceProtocol) -> TrackRepositoryProtocol {
            TrackRepository(service: service)
        }

        func makeCatalogDataSource() -> CatalogDataSourceProtocol {
            CatalogLocalDataSource()
        }

        func makeCatalogRepository(dataSource: CatalogDataSourceProtocol) -> CatalogRepositoryProtocol {
            CatalogRepository(dataSource: dataSource)
        }

        func makeCatalogViewModel(getCatalogUseCase: GetCatalogUseCase) -> CatalogViewModel {
            CatalogViewModel(getCatalogUseCase: getCatalogUseCase)
        }

        networkClient = makeNetworkClient()

        trackService = makeTrackService(client: networkClient)

        trackRepository = makeTrackRepository(service: trackService)

        getTrackPreviewUseCase = GetTrackPreviewUseCase(repository: trackRepository)

        catalogDataSource = makeCatalogDataSource()

        catalogRepository = makeCatalogRepository(dataSource: catalogDataSource)

        getCatalogUseCase = GetCatalogUseCase(repository: catalogRepository)

        catalogViewModel = CatalogViewModel(getCatalogUseCase: getCatalogUseCase)

        audioPlayerManager = AudioPlayerManager(getPreviewUseCase: getTrackPreviewUseCase)
    }
}
