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

        networkClient = makeNetworkClient()

        trackService = makeTrackService(client: networkClient)

        trackRepository = makeTrackRepository(service: trackService)

        getTrackPreviewUseCase = GetTrackPreviewUseCase(repository: trackRepository)

        audioPlayerManager = AudioPlayerManager(getPreviewUseCase: getTrackPreviewUseCase)
    }
}
