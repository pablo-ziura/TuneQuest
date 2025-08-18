import SwiftUI

struct GameOnePlayerView: View {
    @Environment(AudioPlayerManager.self) private var playerManager
    @Environment(GameOnePlayerViewModel.self) private var viewModel

    var body: some View {
        VStack {
            HStack {
                ForEach(0 ..< viewModel.lives, id: \.self) { _ in
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                }
            }

            ScrollView {
                LazyVStack(spacing: 8) {
                    // Drop area at the top of the list
                    Color.red
                        .frame(height: 180)
                        .onDrop(
                            of: [.text],
                            delegate: TrackDropDelegate(
                                item: nil,
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
                                    tracks: viewModel.bindable.tracks,
                                    draggingTrack: viewModel.bindable.draggingTrack,
                                    onDropFinished: viewModel.finalizeDrop
                                )
                            )
                    }
                    // Drop area at the end of the list
                    Color.red
                        .frame(height: 180)
                        .onDrop(
                            of: [.text],
                            delegate: TrackDropDelegate(
                                item: nil,
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
        .alert(viewModel.alertTitle, isPresented: viewModel.bindable.showAlert) {
            Button("OK", role: .cancel) { viewModel.alertTitle = "" }
        }
    }
}

private struct TrackDropDelegate: DropDelegate {
    let item: Track?
    @Binding var tracks: [Track]
    @Binding var draggingTrack: Track?
    let onDropFinished: () -> Void

    func dropEntered(info: DropInfo) {
        guard let draggingTrack else { return }
        // Remove previous temporary placement if the track already exists
        if let fromIndex = tracks.firstIndex(of: draggingTrack) {
            withAnimation { tracks.remove(at: fromIndex) }
        }

        // Insert the new card at the targeted position or at the end
        if let item, let toIndex = tracks.firstIndex(of: item) {
            withAnimation { tracks.insert(draggingTrack, at: toIndex) }
        } else {
            withAnimation { tracks.append(draggingTrack) }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        onDropFinished()
        return true
    }
}
