import SwiftUI

struct HomeView: View {
    @Environment(Router.self) private var router

    var body: some View {
        VStack(spacing: 20) {
            #if DEBUG /* For testing purposes only */
            Button("Posts") {
                router.push(.posts)
            }
            #endif
            Button("One Player") {
                router.push(.gameOnePlayer)
            }
            Button("Multiplayer") {
                router.push(.gameMultiplayer)
            }
            Button("Settings") {
                router.push(.settings)
            }
        }
        .navigationTitle("Home")
        .navigationBarBackButtonHidden(true)
    }
}
