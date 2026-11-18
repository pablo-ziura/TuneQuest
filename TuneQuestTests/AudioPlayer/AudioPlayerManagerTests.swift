import AVFoundation
import Testing
@testable import TuneQuest

@MainActor
@Suite("AudioPlayerManager", .timeLimit(.minutes(1)))
struct AudioPlayerManagerTests {
    @Test("manual preparation stays silent and activates the audio session only on play")
    func manualPlayback() async {
        let repo = MockTrackRepository(result: .success(track(1, preview: "file:///preview.wav")))
        let player = AVPlayer()
        var activations = 0
        let manager = AudioPlayerManager(
            getPreviewUseCase: GetTrackPreviewUseCase(repository: repo), player: player,
            configureSession: { activations += 1 }, deactivateSession: {}
        )

        await manager.loadPreview(trackId: 1, autoplay: false)
        #expect(activations == 0)
        #expect(player.currentItem != nil)
        #expect(player.rate == 0)
        #expect(manager.canPlay)

        manager.play()
        #expect(activations == 1)
        manager.pause()
        manager.play()
        #expect(activations == 1)
        manager.stop()
        #expect(player.rate == 0)
        manager.reset()
    }

    @Test("manual playback reports an activation failure without blocking the song metadata")
    func manualActivationFailure() async {
        let repo = MockTrackRepository(result: .success(track(1, preview: "file:///preview.wav")))
        let manager = AudioPlayerManager(
            getPreviewUseCase: GetTrackPreviewUseCase(repository: repo),
            configureSession: { throw URLError(.unknown) }
        )
        await manager.loadPreview(trackId: 1, autoplay: false)
        #expect(manager.errorMessage == nil)
        manager.play()
        #expect(manager.currentTrack?.id == 1)
        #expect(manager.errorMessage != nil)
        #expect(!manager.canPlay)
        manager.reset()
    }

    private func track(_ id: Int, preview: String? = nil) -> Track {
        Track(dto: TrackDTO(id: id, title: "Track \(id)", preview: preview))
    }

    @Test("a missing preview clears the old player and leaves controls disabled")
    func missingPreviewClearsPlayer() async {
        let expected = track(1)
        let repo = MockTrackRepository(result: .success(expected))
        let player = AVPlayer(playerItem: AVPlayerItem(url: URL(fileURLWithPath: "/unavailable.wav")))
        let manager = AudioPlayerManager(
            getPreviewUseCase: GetTrackPreviewUseCase(repository: repo), player: player, configureSession: {}
        )

        await manager.loadPreview(trackId: 1)
        manager.play()
        manager.togglePlayback()

        #expect(manager.currentTrack == expected)
        #expect(player.currentItem == nil)
        #expect(!manager.canPlay)
        #expect(!manager.isPlaying)
        #expect(!manager.isBuffering)
        #expect(!manager.isLoading)
        #expect(manager.errorMessage == nil)
    }

    @Test("a failed request clears the previous metadata and can be retried")
    func failedRequestAndRetry() async {
        let repo = MockTrackRepository(result: .success(track(1)))
        let manager = AudioPlayerManager(getPreviewUseCase: GetTrackPreviewUseCase(repository: repo))
        await manager.loadPreview(trackId: 1)

        await repo.setResult(.failure(URLError(.notConnectedToInternet)))
        await manager.loadPreview(trackId: 2)
        #expect(manager.currentTrack == nil)
        #expect(manager.errorMessage != nil)
        #expect(!manager.canPlay)
        #expect(!manager.isLoading)

        await repo.setResult(.success(track(2)))
        await manager.loadPreview(trackId: 2)
        #expect(manager.currentTrack == track(2))
        #expect(manager.errorMessage == nil)
    }

    @Test("audio session failure is visible and does not enable playback")
    func audioSessionFailure() async {
        let repo = MockTrackRepository(result: .success(track(1, preview: "file:///preview.wav")))
        let player = AVPlayer()
        let manager = AudioPlayerManager(
            getPreviewUseCase: GetTrackPreviewUseCase(repository: repo), player: player,
            configureSession: { throw URLError(.unknown) }
        )

        await manager.loadPreview(trackId: 1)

        #expect(manager.currentTrack?.id == 1)
        #expect(manager.errorMessage != nil)
        #expect(!manager.canPlay)
        #expect(!manager.isPlaying)
        #expect(player.currentItem == nil)
    }

    @Test("an older response cannot replace the selected track or finish its loading state")
    func discardsOutOfOrderResponses() async {
        let repo = SuspendedTrackRepository()
        let manager = AudioPlayerManager(getPreviewUseCase: GetTrackPreviewUseCase(repository: repo))
        let first = Task { await manager.loadPreview(trackId: 1) }
        await repo.waitUntilRequested(1)
        let second = Task { await manager.loadPreview(trackId: 2) }
        await repo.waitUntilRequested(2)

        await repo.complete(1, with: track(1))
        await first.value
        #expect(manager.currentTrack == nil)
        #expect(manager.isLoading)

        await repo.complete(2, with: track(2))
        await second.value
        #expect(manager.currentTrack == track(2))
        #expect(!manager.isLoading)
    }

    @Test("leaving the screen invalidates a late preview response")
    func resetDiscardsLateResponse() async {
        let repo = SuspendedTrackRepository()
        let manager = AudioPlayerManager(getPreviewUseCase: GetTrackPreviewUseCase(repository: repo))
        let task = Task { await manager.loadPreview(trackId: 1) }
        await repo.waitUntilRequested(1)

        manager.reset()
        await repo.complete(1, with: track(1))
        await task.value

        #expect(manager.currentTrack == nil)
        #expect(manager.errorMessage == nil)
        #expect(!manager.isLoading)
        #expect(!manager.canPlay)
    }

    @Test("task cancellation discards metadata without showing an error")
    func cancellationIsSilent() async {
        let repo = SuspendedTrackRepository()
        let manager = AudioPlayerManager(getPreviewUseCase: GetTrackPreviewUseCase(repository: repo))
        let task = Task { await manager.loadPreview(trackId: 1) }
        await repo.waitUntilRequested(1)
        task.cancel()
        await repo.complete(1, with: track(1))
        await task.value

        #expect(manager.currentTrack == nil)
        #expect(manager.errorMessage == nil)
        #expect(!manager.isLoading)
        #expect(!manager.isPlaying)
    }

    @Test("reset releases the audio item and deactivates the session once")
    func resetReleasesAudioSession() async {
        let repo = MockTrackRepository(result: .success(track(1, preview: "file:///preview.wav")))
        let player = AVPlayer()
        var deactivations = 0
        let manager = AudioPlayerManager(
            getPreviewUseCase: GetTrackPreviewUseCase(repository: repo), player: player,
            configureSession: {}, deactivateSession: { deactivations += 1 }
        )
        await manager.loadPreview(trackId: 1)
        manager.reset()
        manager.reset()

        #expect(deactivations == 1)
        #expect(player.currentItem == nil)
        #expect(manager.currentTrack == nil)
        #expect(!manager.isPlaying)
        #expect(!manager.isBuffering)
    }
}
