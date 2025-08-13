import SwiftUI

struct AudioPlayerManagerView: View {
    @Environment(AudioPlayerManager.self) private var manager

    var body: some View {
        VStack(spacing: 24) {
            if manager.isLoading {
                ProgressView("Cargando preview…")
            } else {
                HStack(spacing: 32) {
                    Button(action: { manager.togglePlayback() }) {
                        Image(systemName: manager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 48))
                    }
                    Button(action: { manager.stop() }) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 48))
                    }
                }
            }
        }
        .onDisappear {
            manager.stop()
        }
    }
}
