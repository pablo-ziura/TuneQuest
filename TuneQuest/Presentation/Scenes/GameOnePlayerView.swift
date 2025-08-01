import SwiftUI
import AVFoundation

struct GameOnePlayerView: View {
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var loading = true     // Mientras descargamos la URL

    var body: some View {
        VStack(spacing: 24) {
            if loading {
                ProgressView("Cargando preview…")
            } else {
                Button(isPlaying ? "Pausar" : "Reproducir") {
                    togglePlayback()
                }
                .font(.title2)
            }
        }
        .padding()
        .task {      // Swift 5.5+ async/await
            await configureAudioSession()
            await fetchPreviewAndPlay(trackId: 3135556)
        }
    }

    private func togglePlayback() {
        guard let player = player else { return }
        if player.timeControlStatus == .playing {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    private func configureAudioSession() async {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Sesión de audio: \(error)")
        }
    }

    private func fetchPreviewAndPlay(trackId: Int) async {
        do {
            let url = URL(string: "https://api.deezer.com/track/\(trackId)")!
            let (data, _) = try await URLSession.shared.data(from: url)
            guard
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let previewString = json["preview"] as? String,
                let previewURL = URL(string: previewString)
            else {
                print("No se encontró campo preview")
                return
            }

            await MainActor.run {
                self.player = AVPlayer(url: previewURL)
                self.player?.play()
                self.isPlaying = true
                self.loading = false
            }
        } catch {
            print("Error de red: \(error)")
        }
    }
}
