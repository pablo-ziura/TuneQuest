import Foundation
import SwiftUI
import TuneNetwork

@MainActor
@Observable
final class AppCoordinator {
    let networkClient: NetworkClientProtocol
    init() {
        guard let baseUrl = Bundle.main.infoDictionary?["BASE_URL"] as? String else {
            fatalError("Entry not found for BASE_URL")
        }

        networkClient = NetworkClient(baseUrl: baseUrl)

    }

    func getContentView() -> some View {
        ContentView()
            .environment(self)
    }

    func getPostsView() -> some View {
        PostsView()
            .environment(self)
    }
}
