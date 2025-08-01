import SwiftUI
import AVFoundation

@MainActor
@Observable
final class PreviewPlayerManager {
    private var player: AVPlayer?
    var isPlaying = false
    var isLoading = false

    func loadPreview(trackId: Int) async {
        isLoading = true
        defer { isLoading = false }
        await configureAudioSession()
        await fetchPreview(trackId: trackId)
    }

    func togglePlayback() {
        guard let player else { return }
        if player.timeControlStatus == .playing {
            pause()
        } else {
            play()
        }
    }

    func play() {
        player?.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
    }

    private func configureAudioSession() async {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Sesión de audio: \(error)")
        }
    }

    private func fetchPreview(trackId: Int) async {
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
            self.player = AVPlayer(url: previewURL)
            play()
        } catch {
            print("Error de red: \(error)")
        }
    }
}
