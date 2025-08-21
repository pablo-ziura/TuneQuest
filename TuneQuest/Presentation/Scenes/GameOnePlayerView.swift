import SwiftUI

struct GameOnePlayerView: View {
    @Environment(AudioPlayerManager.self) private var playerManager
    @Environment(GameOnePlayerViewModel.self) private var viewModel

    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.tracks.enumerated()), id: \.element) { index, track in
                        DropIndicator(isActive: viewModel.dragOverIndex == index)
                            .frame(height: 8)
                            .onDrop(
                                of: [.text],
                                delegate: TrackDropDelegate(
                                    index: index,
                                    tracks: viewModel.bindable.tracks,
                                    draggingTrack: viewModel.bindable.draggingTrack,
                                    dragOverIndex: viewModel.bindable.dragOverIndex,
                                    onDropFinished: viewModel.finalizeDrop
                                )
                            )

                        TrackRowView(track: track)
                            .frame(height: 80)
                            .onDrag {
                                viewModel.draggingTrack = track
                                playerManager.stop()
                                return NSItemProvider(object: NSString(string: track.id.map(String.init) ?? ""))
                            }
                            .onDrop(
                                of: [.text],
                                delegate: TrackDropDelegate(
                                    index: index + 1,
                                    tracks: viewModel.bindable.tracks,
                                    draggingTrack: viewModel.bindable.draggingTrack,
                                    dragOverIndex: viewModel.bindable.dragOverIndex,
                                    onDropFinished: viewModel.finalizeDrop
                                )
                            )
                    }

                    DropIndicator(isActive: viewModel.dragOverIndex == viewModel.tracks.count)
                        .frame(height: 8)
                        .onDrop(
                            of: [.text],
                            delegate: TrackDropDelegate(
                                index: viewModel.tracks.count,
                                tracks: viewModel.bindable.tracks,
                                draggingTrack: viewModel.bindable.draggingTrack,
                                dragOverIndex: viewModel.bindable.dragOverIndex,
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
    let index: Int
    @Binding var tracks: [Track]
    @Binding var draggingTrack: Track?
    @Binding var dragOverIndex: Int?
    let onDropFinished: () -> Void

    func dropEntered(info: DropInfo) {
        dragOverIndex = index
    }

    func dropExited(info: DropInfo) {
        dragOverIndex = nil
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let draggingTrack else { return false }
        var targetIndex = index

        if let fromIndex = tracks.firstIndex(of: draggingTrack) {
            tracks.remove(at: fromIndex)
            if fromIndex < targetIndex {
                targetIndex -= 1
            }
        }

        withAnimation {
            tracks.insert(draggingTrack, at: targetIndex)
        }

        dragOverIndex = nil
        onDropFinished()
        return true
    }
}

private struct DropIndicator: View {
    let isActive: Bool

    var body: some View {
        Rectangle()
            .fill(isActive ? Color.accentColor.opacity(0.5) : .clear)
            .frame(height: 4)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
    }
}
