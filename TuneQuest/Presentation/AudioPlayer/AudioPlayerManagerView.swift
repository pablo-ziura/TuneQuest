import SwiftUI

struct AudioPlayerManagerView: View {
    @Environment(AudioPlayerManager.self) private var manager

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 32) {
                Button(action: manager.togglePlayback) {
                    Label(
                        manager.isPlaying || manager.isBuffering ? "Pause" : "Play",
                        systemImage: manager.isPlaying || manager.isBuffering ? "pause.circle.fill" : "play.circle.fill"
                    )
                    .labelStyle(.iconOnly)
                    .font(.largeTitle)
                    .frame(minWidth: 56, minHeight: 56)
                }
                Button(action: manager.stop) {
                    Label("Stop", systemImage: "stop.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.largeTitle)
                        .frame(minWidth: 56, minHeight: 56)
                }
            }
            .disabled(!manager.canPlay)

            if manager.isBuffering {
                ProgressView("Buffering preview…")
            }
        }
    }
}
