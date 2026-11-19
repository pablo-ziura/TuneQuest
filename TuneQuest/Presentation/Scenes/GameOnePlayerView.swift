import SwiftUI

struct GameOnePlayerView: View {
    @Environment(AudioPlayerManager.self) private var playerManager
    @Environment(CatalogViewModel.self) private var viewModel
    @State private var currentIndex = 0
    @State private var catalogAttempt = 0
    @State private var trackAttempt = 0

    private struct TrackRequest: Equatable {
        let id: Int?
        let attempt: Int
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.isLoading || (viewModel.catalog == nil && viewModel.errorMessage == nil) {
                    ProgressView("Loading catalog…")
                } else if let message = viewModel.errorMessage {
                    ContentUnavailableView {
                        Label("Catalog unavailable", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Retry") { catalogAttempt += 1 }
                            .buttonStyle(.bordered)
                    }
                } else if let ids = viewModel.catalog?.ids, ids.isEmpty {
                    ContentUnavailableView("The catalog is empty", systemImage: "music.note.list",
                                           description: Text("There are no tracks to preview yet."))
                } else if let ids = viewModel.catalog?.ids {
                    Text("Track \(currentIndex + 1) of \(ids.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    trackContent

                    HStack {
                        Button { selectTrack(at: currentIndex - 1) } label: {
                            Label("Previous track", systemImage: "backward.fill")
                                .labelStyle(.iconOnly)
                                .font(.title2)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .disabled(currentIndex == 0 || playerManager.isLoading)

                        Spacer()

                        Button { selectTrack(at: currentIndex + 1) } label: {
                            Label("Next track", systemImage: "forward.fill")
                                .labelStyle(.iconOnly)
                                .font(.title2)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .disabled(currentIndex >= ids.count - 1 || playerManager.isLoading)
                    }

                    Text("Audio previews provided by Deezer")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Catalog previews")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: catalogAttempt) {
            await viewModel.fetchData()
        }
        .task(id: trackRequest) {
            guard let id = trackRequest.id else { return }
            await playerManager.loadPreview(trackId: id)
        }
        .onDisappear {
            viewModel.cancelLoading()
            playerManager.reset()
        }
    }

    @ViewBuilder
    private var trackContent: some View {
        if playerManager.isLoading {
            ProgressView("Loading preview…")
                .frame(minHeight: 200)
        } else if let track = playerManager.currentTrack {
            artwork(for: track)

            VStack(spacing: 8) {
                Text(track.title ?? "Unknown title")
                    .font(.title2.bold())
                Text(track.artist?.name ?? "Unknown artist")
                    .font(.headline)
                if let date = track.releaseDate, !date.isEmpty {
                    Text(String(date.prefix(4)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)

            if track.preview == nil {
                Text("No audio preview is available for this track.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            AudioPlayerManagerView()
        }

        if let message = playerManager.errorMessage {
            ContentUnavailableView {
                Label("Preview unavailable", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Retry preview") { trackAttempt += 1 }
                    .buttonStyle(.bordered)
            }
        }
    }

    private var trackRequest: TrackRequest {
        let ids = viewModel.catalog?.ids ?? []
        let id = ids.indices.contains(currentIndex) ? ids[currentIndex] : nil
        return TrackRequest(id: id, attempt: trackAttempt)
    }

    private func selectTrack(at index: Int) {
        guard !playerManager.isLoading, let ids = viewModel.catalog?.ids, ids.indices.contains(index) else { return }
        currentIndex = index
    }

    private func artwork(for track: Track) -> some View {
        AsyncImage(url: track.album?.coverBig.flatMap(URL.init(string:))) { phase in
            if let image = phase.image {
                image.resizable().scaledToFit()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(.quaternary)
                    Image(systemName: "music.note")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityHidden(true)
    }
}
