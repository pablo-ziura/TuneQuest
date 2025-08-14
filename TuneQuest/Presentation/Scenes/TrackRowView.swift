import SwiftUI

struct TrackRowView: View {
    @Environment(AudioPlayerManager.self) private var playerManager
    let track: Track

    private var isCurrentTrack: Bool {
        playerManager.currentTrack?.id == track.id
    }

    private var isPlayingCurrentTrack: Bool {
        isCurrentTrack && playerManager.isPlaying
    }

    private var releaseYear: String? {
        if let dateString = track.releaseDate ?? track.album?.releaseDate {
            return String(dateString.prefix(4))
        }
        return nil
    }

    var body: some View {
        HStack(spacing: 12) {
            if let cover = track.album?.coverSmall, let url = URL(string: cover) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title ?? "Título desconocido")
                    .font(.subheadline)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(track.artist?.name ?? "Artista desconocido")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if let year = releaseYear {
                        Text("• \(year)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Button {
                if isCurrentTrack {
                    playerManager.togglePlayback()
                } else if let id = track.id {
                    Task { await playerManager.loadPreview(trackId: id) }
                }
            } label: {
                Image(systemName: isPlayingCurrentTrack ? "pause.fill" : "play.fill")
                    .font(.title2)
            }
            Button {
                playerManager.stop()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.title2)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
