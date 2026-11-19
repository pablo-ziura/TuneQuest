import Foundation
import SwiftUI
import TuneNetwork

@MainActor
@Observable
final class AppCoordinator {
    let container: DependencyContainer
    var router: Router {
        container.router
    }

    init() {
        container = DependencyContainer.shared
    }

    func getContentView() -> some View {
        ContentView()
            .environment(self)
            .environment(router)
    }

    func getHomeView() -> some View {
        HomeView()
            .environment(self)
            .environment(router)
    }

    func getGameOnePlayerView() -> some View {
        GameOnePlayerView()
            .environment(self)
            .environment(router)
            .environment(container.audioPlayerManager)
            .environment(container.catalogViewModel)
            .environment(container.gameOnePlayerViewModel)
    }

    func getGameMultiplayerView() -> some View {
        GameMultiplayerView()
            .environment(self)
            .environment(router)
    }

    func getSettingsView() -> some View {
        SettingsView()
            .environment(self)
            .environment(router)
    }

    @ViewBuilder
    func destination(for route: Route) -> some View {
        switch route {
        case .home:
            getHomeView()
        case .gameOnePlayer:
            getGameOnePlayerView()
        case .gameMultiplayer:
            getGameMultiplayerView()
        case .settings:
            getSettingsView()
        }
    }
}
