import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Content View")
                NavigationLink("Go to Home") {
                    coordinator.getHomeView()
                }
            }
        }
    }
}
