import SwiftUI
import SwiftData

@main
struct TuneQuestApp: App {
    @State private var coordinator: AppCoordinator

    init() {
        coordinator = AppCoordinator()
    }

    var body: some Scene {
        WindowGroup {
            coordinator.getContentView()
        }
    }
}
