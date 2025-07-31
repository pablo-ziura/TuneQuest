import SwiftUI

struct HomeView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        VStack(spacing: 20) {
            NavigationLink("One Player") {
                coordinator.getGameOnePlayerView()
            }
            NavigationLink("Multiplayer") {
                coordinator.getGameMultiplayerView()
            }
            NavigationLink("Settings") {
                coordinator.getSettingsView()
            }
        }
        .navigationTitle("Home")
    }
}
