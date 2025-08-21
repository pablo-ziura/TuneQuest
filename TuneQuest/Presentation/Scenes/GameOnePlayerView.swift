import SwiftUI

struct GameOnePlayerView: View {
    @Environment(AudioPlayerManager.self) private var playerManager
    @Environment(GameOnePlayerViewModel.self) private var viewModel

    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 8) {
                    // Drop area at the top of the list
                    Color.clear
                        .frame(height: 80)
                        .onDrop(
                            of: [.text],
                            delegate: TrackDropDelegate(
                                item: nil,
                                index: 0,
                                tracks: viewModel.bindable.tracks,
                                draggingTrack: viewModel.bindable.draggingTrack,
                                onDropFinished: viewModel.finalizeDrop
                            )
                        )

                    ForEach(viewModel.tracks, id: \.self) { track in
                        TrackRowView(track: track)
                            .frame(height: 80)
                            .onDrop(
                                of: [.text],
                                delegate: TrackDropDelegate(
                                    item: track,
                                    index: nil,
                                    tracks: viewModel.bindable.tracks,
                                    draggingTrack: viewModel.bindable.draggingTrack,
                                    onDropFinished: viewModel.finalizeDrop
                                )
                            )
                    }
                    // Drop area at the end of the list
                    Color.clear
                        .frame(height: 80)
                        .onDrop(
                            of: [.text],
                            delegate: TrackDropDelegate(
                                item: nil,
                                index: viewModel.tracks.count,
                                tracks: viewModel.bindable.tracks,
                                draggingTrack: viewModel.bindable.draggingTrack,
                                onDropFinished: viewModel.finalizeDrop
                            )
                        )
                }
                .padding()
            }

            if let newCard = viewModel.newCard {
                TrackRowView(track: newCard)
                    .frame(height: 80)
                    .padding(.horizontal)
                    .onDrag {
                        viewModel.draggingTrack = newCard
                        playerManager.stop()
                        return NSItemProvider(object: NSString(string: newCard.id.map(String.init) ?? ""))
                    }
            }

            Button("New Card") {
                Task { await viewModel.addNewCard() }
            }
            .disabled(!viewModel.canAddCard)
            .padding()
        }
        .task { await viewModel.loadInitialTrack() }
        .navigationTitle("One Player")
    }
}

private struct TrackDropDelegate: DropDelegate {
    let item: Track?
    let index: Int?
    @Binding var tracks: [Track]
    @Binding var draggingTrack: Track?
    let onDropFinished: () -> Void

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let draggingTrack else { return false }

        let targetIndex: Int
        if let index {
            targetIndex = index
        } else if let item, let toIndex = tracks.firstIndex(of: item) {
            targetIndex = toIndex
        } else {
            targetIndex = tracks.count
        }

        withAnimation {
            tracks.insert(draggingTrack, at: targetIndex)
        }

        onDropFinished()
        return true
    }
}
