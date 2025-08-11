import SwiftUI

struct GameOnePlayerView: View {
    @Environment(AudioPlayerManager.self) private var playerManager
    @Environment(CatalogViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 32) {
            Text("Deezer Preview")
                .font(.title2)
            AudioPlayerManagerView()
        }
        .padding()
        .task {
            await playerManager.loadPreview(trackId: 3135556)
        }
        .navigationTitle("One Player")
    }
}
