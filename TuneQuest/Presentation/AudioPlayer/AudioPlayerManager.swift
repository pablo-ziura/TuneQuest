import SwiftUI
import AVFoundation

@MainActor
@Observable
final class AudioPlayerManager {
    private let getPreviewUseCase: GetTrackPreviewUseCase
    private var player: AVPlayer?
    var isPlaying = false
    var isLoading = false

    init(getPreviewUseCase: GetTrackPreviewUseCase) {
        self.getPreviewUseCase = getPreviewUseCase
    }

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
            let preview = try await getPreviewUseCase.execute(trackId: trackId)
            self.player = AVPlayer(url: preview.url)
            play()
        } catch {
            print("Error de red: \(error)")
        }
    }
}
