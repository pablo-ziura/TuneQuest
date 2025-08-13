import SwiftUI

struct GameOnePlayerView: View {
    @Environment(AudioPlayerManager.self) private var playerManager
    @Environment(CatalogViewModel.self) private var viewModel
    @State private var tracks: [Track] = []
    @State private var draggingTrack: Track?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(tracks, id: \.self) { track in
                    TrackRowView(track: track)
                        .frame(height: 80)
                        .onDrag {
                            draggingTrack = track
                            playerManager.stop()
                            return NSItemProvider(object: NSString(string: track.id.map(String.init) ?? ""))
                        }
                        .onDrop(
                            of: [.text],
                            delegate: TrackDropDelegate(
                                item: track,
                                tracks: $tracks,
                                draggingTrack: $draggingTrack
                            )
                        )
                }
            }
            .padding()
        }
        .scrollDisabled(draggingTrack != nil)
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

private struct TrackDropDelegate: DropDelegate {
    let item: Track
    @Binding var tracks: [Track]
    @Binding var draggingTrack: Track?

    func dropEntered(info: DropInfo) {
        guard let draggingTrack,
              draggingTrack != item,
              let fromIndex = tracks.firstIndex(of: draggingTrack),
              let toIndex = tracks.firstIndex(of: item)
        else { return }

        withAnimation {
            tracks.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingTrack = nil
        return true
    }
}
