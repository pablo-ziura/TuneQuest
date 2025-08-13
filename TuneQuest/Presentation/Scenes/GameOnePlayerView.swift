import SwiftUI

struct GameOnePlayerView: View {
    @Environment(AudioPlayerManager.self) private var playerManager
    @Environment(CatalogViewModel.self) private var viewModel
    @State private var tracks: [Track] = []

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(tracks, id: \.self) { track in
                    TrackRowView(track: track)
                        .frame(height: 80)
                }
            }
            .padding()
        }
        .task {
            await viewModel.fetchData()
            tracks = []
            if let ids = viewModel.catalog?.ids {
                for id in ids {
                    if let track = await playerManager.trackInfo(for: id) {
                        tracks.append(track)
                    }
                }
            }
        }
        .navigationTitle("One Player")
    }
}
