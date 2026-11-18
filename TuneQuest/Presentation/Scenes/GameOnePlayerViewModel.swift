import Foundation
import Observation

@MainActor
@Observable
final class GameOnePlayerViewModel {
    let player: AudioPlayerManager
    private let startGame: StartSinglePlayerGameUseCase
    private var loadID = UUID()
    private var isActive = false

    private(set) var session: GameSession?
    private(set) var selectedPosition: Int?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var previewRequestID = UUID()

    var canConfirm: Bool { session?.phase == .placing && selectedPosition != nil }

    init(startGame: StartSinglePlayerGameUseCase, player: AudioPlayerManager) {
        self.startGame = startGame
        self.player = player
    }

    func start() async {
        guard !Task.isCancelled else { return }
        let id = UUID()
        loadID = id
        isActive = true
        player.reset()
        session = nil
        selectedPosition = nil
        errorMessage = nil
        isLoading = true
        defer { if loadID == id { isLoading = false } }

        do {
            let game = try await startGame.execute()
            try Task.checkCancellation()
            guard isActive, loadID == id else { return }
            session = game
            previewRequestID = UUID()
        } catch {
            guard isActive, loadID == id, !Task.isCancelled, !(error is CancellationError) else { return }
            errorMessage = "A new game could not be prepared. Please try again."
        }
    }

    func selectPosition(_ index: Int) {
        guard let session, session.phase == .placing, (0...session.timeline.count).contains(index) else { return }
        selectedPosition = index
    }

    func confirm() {
        guard canConfirm, let selectedPosition else { return }
        player.pause()
        session?.confirm(at: selectedPosition)
        self.selectedPosition = nil
        if session?.phase.isFinished == true { player.reset() }
    }

    func advance() {
        guard let phase = session?.phase, phase == .correct || phase == .incorrect else { return }
        session?.advance()
        selectedPosition = nil
        if phase == .correct {
            player.reset()
            previewRequestID = UUID()
        }
    }

    func preparePreview() async {
        guard isActive, let session, !session.phase.isFinished else { return }
        await player.loadPreview(trackId: session.pendingTrack.id, autoplay: false)
    }

    func retryPreview() {
        guard isActive, session?.phase == .placing else { return }
        previewRequestID = UUID()
    }

    func cancel() {
        isActive = false
        loadID = UUID()
        session = nil
        selectedPosition = nil
        isLoading = false
        errorMessage = nil
        player.reset()
    }
}
