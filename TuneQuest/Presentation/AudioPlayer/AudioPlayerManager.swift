import AVFoundation
import OSLog
import SwiftUI

@MainActor
@Observable
final class AudioPlayerManager {
    private let getPreviewUseCase: GetTrackPreviewUseCase
    private let player: AVPlayer
    private let configureSession: () throws -> Void
    private let deactivateSession: () throws -> Void
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TuneQuest", category: "Audio")
    private var loadID = UUID()
    private var hasFinished = false
    private var isSessionActive = false

    @ObservationIgnored private var playbackObservation: NSKeyValueObservation?
    @ObservationIgnored private var itemObservation: NSKeyValueObservation?
    @ObservationIgnored private var notificationObservers: [NSObjectProtocol] = []

    private(set) var isPlaying = false
    private(set) var isLoading = false
    private(set) var isBuffering = false
    private(set) var currentTrack: Track?
    private(set) var errorMessage: String?

    var canPlay: Bool {
        currentTrack?.preview != nil && !isLoading && errorMessage == nil
    }

    init(
        getPreviewUseCase: GetTrackPreviewUseCase,
        player: AVPlayer = AVPlayer(),
        configureSession: @escaping () throws -> Void = {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        },
        deactivateSession: @escaping () throws -> Void = {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    ) {
        self.getPreviewUseCase = getPreviewUseCase
        self.player = player
        self.configureSession = configureSession
        self.deactivateSession = deactivateSession
        playbackObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.updatePlaybackState()
            }
        }
    }

    deinit {
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    func trackInfo(for trackId: Int) async -> Track? {
        do {
            return try await getPreviewUseCase.execute(trackId: trackId)
        } catch {
            print("Error de red: \(error)")
            return nil
        }
    }

    func loadPreview(trackId: Int) async {
        guard !Task.isCancelled else { return }
        clearPreview()
        let id = loadID
        isLoading = true
        defer {
            if loadID == id { isLoading = false }
        }

        do {
            let track = try await getPreviewUseCase.execute(trackId: trackId)
            try Task.checkCancellation()
            guard loadID == id else { return }
            currentTrack = track
            guard let url = track.preview else {
                releaseAudioSession()
                return
            }
            try configureSession()
            isSessionActive = true

            let item = AVPlayerItem(url: url)
            observe(item, loadID: id)
            player.replaceCurrentItem(with: item)
            player.play()
            updatePlaybackState()
        } catch {
            guard loadID == id, !Task.isCancelled, !(error is CancellationError) else { return }
            failPlayback()
            logger.error("Preview failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func togglePlayback() {
        guard canPlay else { return }
        if player.timeControlStatus == .playing || player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
            pause()
        } else {
            play()
        }
    }

    func play() {
        guard canPlay else { return }
        if hasFinished {
            player.seek(to: .zero)
            hasFinished = false
        }
        player.play()
        updatePlaybackState()
    }

    func pause() {
        player.pause()
        updatePlaybackState()
    }

    func stop() {
        player.pause()
        player.seek(to: .zero)
        hasFinished = false
        updatePlaybackState()
    }

    /// Invalidates in-flight responses as well as releasing the current audio item.
    func reset() {
        clearPreview()
        releaseAudioSession()
    }

    private func clearPreview() {
        loadID = UUID()
        itemObservation = nil
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
        notificationObservers.removeAll()
        player.pause()
        player.replaceCurrentItem(with: nil)
        hasFinished = false
        currentTrack = nil
        errorMessage = nil
        isLoading = false
        updatePlaybackState()
    }

    private func observe(_ item: AVPlayerItem, loadID id: UUID) {
        itemObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                guard let self, self.loadID == id else { return }
                if self.player.currentItem?.status == .failed {
                    self.failPlayback()
                }
            }
        }

        let center = NotificationCenter.default
        notificationObservers.append(center.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification, object: item, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.loadID == id else { return }
                self.hasFinished = true
                self.player.pause()
                self.updatePlaybackState()
            }
        })
        notificationObservers.append(center.addObserver(
            forName: AVPlayerItem.failedToPlayToEndTimeNotification, object: item, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.loadID == id else { return }
                self.failPlayback()
            }
        })
    }

    private func updatePlaybackState() {
        isPlaying = player.timeControlStatus == .playing
        isBuffering = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
    }

    private func failPlayback() {
        player.pause()
        errorMessage = "This preview could not be played. Check your connection and try again."
        updatePlaybackState()
        releaseAudioSession()
    }

    private func releaseAudioSession() {
        guard isSessionActive else { return }
        do {
            try deactivateSession()
            isSessionActive = false
        } catch {
            logger.error("Audio session deactivation failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
