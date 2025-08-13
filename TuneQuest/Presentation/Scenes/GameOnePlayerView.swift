import SwiftUI

struct GameOnePlayerView: View {
    @Environment(AudioPlayerManager.self) private var playerManager
    @Environment(CatalogViewModel.self) private var viewModel
    @State private var currentIndex = 0

    var body: some View {
        VStack(spacing: 32) {
            if let track = playerManager.currentTrack {
                VStack(spacing: 8) {
                    if let cover = track.album?.coverBig, let url = URL(string: cover) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 200, height: 200)
                        .cornerRadius(12)
                    }
                    Text(track.title ?? "Título desconocido")
                        .font(.title2)
                        .multilineTextAlignment(.center)
                    Text(track.artist?.name ?? "Artista desconocido")
                        .font(.headline)
                    if let year = track.releaseDate?.prefix(4) {
                        Text(String(year))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                ProgressView()
            }

            AudioPlayerManagerView()

            HStack {
                Button {
                    Task { await previousTrack() }
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title)
                }
                .disabled(currentIndex == 0)

                Spacer()

                Button {
                    Task { await nextTrack() }
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title)
                }
                .disabled(isLastTrack)
            }
            .padding(.horizontal)
        }
        .padding()
        .task {
            await viewModel.fetchData()
            await loadTrack(at: currentIndex)
        }
        .navigationTitle("One Player")
    }

    private var isLastTrack: Bool {
        guard let ids = viewModel.catalog?.ids else { return true }
        return currentIndex >= ids.count - 1
    }

    private func loadTrack(at index: Int) async {
        guard let ids = viewModel.catalog?.ids, ids.indices.contains(index) else { return }
        await playerManager.loadPreview(trackId: ids[index])
    }

    private func nextTrack() async {
        currentIndex += 1
        await loadTrack(at: currentIndex)
    }

    private func previousTrack() async {
        currentIndex -= 1
        await loadTrack(at: currentIndex)
    }
}
