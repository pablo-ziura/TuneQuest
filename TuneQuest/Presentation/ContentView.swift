import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        NavigationStack {
            coordinator.getPostsView()
        }
    }
}
