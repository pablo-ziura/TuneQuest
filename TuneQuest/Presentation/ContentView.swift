import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(Router.self) private var router

    var body: some View {
        NavigationStack(path: router.path.binding) {
            VStack(spacing: 20) {
                Text("Content View")
                Button("Go to Home") {
                    router.push(.home)
                }
            }
            .navigationDestination(for: Route.self) { route in
                coordinator.destination(for: route)
            }
        }
    }
}
