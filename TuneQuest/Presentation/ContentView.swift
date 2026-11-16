import SwiftUI

struct ContentView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(Router.self) private var router

    var body: some View {
        NavigationStack(path: router.pathBinding) {
            coordinator.getHomeView()
            .navigationDestination(for: Route.self) { route in
                coordinator.destination(for: route)
            }
        }
    }
}
