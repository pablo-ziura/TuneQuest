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
    let catalogService: CatalogServiceProtocol
    let catalogRepository: CatalogRepositoryProtocol
    let getCatalogUseCase: GetCatalogUseCase
    let audioPlayerManager: AudioPlayerManager
    let catalogViewModel: CatalogViewModel

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

        func makeCatalogService() -> CatalogServiceProtocol {
            CatalogService()
        }

        func makeCatalogRepository(service: CatalogServiceProtocol) -> CatalogRepositoryProtocol {
            CatalogRepository(service: service)
        }

        networkClient = makeNetworkClient()

        trackService = makeTrackService(client: networkClient)

        trackRepository = makeTrackRepository(service: trackService)

        getTrackPreviewUseCase = GetTrackPreviewUseCase(repository: trackRepository)

        catalogService = makeCatalogService()

        catalogRepository = makeCatalogRepository(service: catalogService)

        getCatalogUseCase = GetCatalogUseCase(repository: catalogRepository)

        catalogViewModel = CatalogViewModel(getCatalogUseCase: getCatalogUseCase)

        audioPlayerManager = AudioPlayerManager(getPreviewUseCase: getTrackPreviewUseCase)
    }
}
