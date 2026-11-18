import AVFoundation
import Testing
@testable import TuneQuest

@MainActor
@Suite("GameOnePlayerViewModel")
struct GameOnePlayerViewModelTests {
    @Test("an older start cannot replace a newer game or finish its loading state")
    func overlappingStarts() async {
        let repo = SequencedCatalogRepository()
        let vm = makeModel(repository: repo)
        let first = Task { await vm.start() }
        await repo.waitUntilRequested(1)
        let second = Task { await vm.start() }
        await repo.waitUntilRequested(2)
        await repo.complete(1, with: Catalog(entries: [gameEntry(1), gameEntry(2)]))
        await first.value
        #expect(vm.session == nil)
        #expect(vm.isLoading)
        await repo.complete(2, with: Catalog(entries: [gameEntry(3), gameEntry(4)]))
        await second.value
        #expect(vm.session?.timeline.first?.id == 3)
        #expect(!vm.isLoading)
    }

    @Test("a preview completing after game over cannot restore audio metadata")
    func gameOverDiscardsPreview() async {
        let catalog = MockCatalogRepository(result: .success(Catalog(entries: [gameEntry(1), gameEntry(2)])))
        let tracks = SuspendedTrackRepository()
        let vm = GameOnePlayerViewModel(
            startGame: StartSinglePlayerGameUseCase(repository: catalog,
                configuration: .init(targetCorrectPlacements: 1), shuffle: { $0 }),
            player: AudioPlayerManager(getPreviewUseCase: GetTrackPreviewUseCase(repository: tracks))
        )
        await vm.start()
        let preview = Task { await vm.preparePreview() }
        await tracks.waitUntilRequested(2)
        vm.selectPosition(1)
        vm.confirm()
        await tracks.complete(2, with: Track(dto: TrackDTO(id: 2, preview: "file:///preview.wav")))
        await preview.value
        #expect(vm.session?.phase == .won)
        #expect(vm.player.currentTrack == nil)
        #expect(!vm.player.canPlay)
    }

    private func makeModel(repository: CatalogRepositoryProtocol) -> GameOnePlayerViewModel {
        GameOnePlayerViewModel(
            startGame: StartSinglePlayerGameUseCase(repository: repository,
                configuration: .init(targetCorrectPlacements: 1), shuffle: { $0 }),
            player: AudioPlayerManager(getPreviewUseCase: GetTrackPreviewUseCase(
                repository: MockTrackRepository(result: .failure(URLError(.notConnectedToInternet)))))
        )
    }

    @Test("selection, retries, victory and restart form a complete session")
    func completeFlow() async {
        let repo = MockCatalogRepository(result: .success(Catalog(entries: [gameEntry(1), gameEntry(2, year: 2010)])))
        let vm = makeModel(repository: repo)
        await vm.start()
        #expect(!vm.canConfirm)
        vm.selectPosition(-1)
        #expect(!vm.canConfirm)
        vm.selectPosition(0)
        vm.confirm()
        vm.confirm()
        #expect(vm.session?.remainingLives == 2)
        #expect(vm.session?.phase == .incorrect)
        vm.advance()
        #expect(vm.selectedPosition == nil)
        vm.selectPosition(1)
        vm.confirm()
        #expect(vm.session?.phase == .won)
        await vm.start()
        #expect(vm.session?.remainingLives == 3)
        #expect(vm.session?.correctPlacements == 0)
        #expect(vm.session?.phase == .placing)
    }

    @Test("preview failures do not prevent a confirmed answer")
    func audioFailureIsIndependent() async {
        let repo = MockCatalogRepository(result: .success(Catalog(entries: [gameEntry(1), gameEntry(2)])))
        let vm = makeModel(repository: repo)
        await vm.start()
        await vm.preparePreview()
        #expect(vm.player.errorMessage != nil)
        let request = vm.previewRequestID
        vm.retryPreview()
        #expect(vm.previewRequestID != request)
        vm.selectPosition(1)
        vm.confirm()
        #expect(vm.session?.phase == .won)
        #expect(vm.player.currentTrack == nil)
    }

    @Test("a loading failure can be retried")
    func retryLoading() async {
        let repo = MockCatalogRepository(result: .failure(CatalogDataSourceError.fileNotFound))
        let vm = makeModel(repository: repo)
        await vm.start()
        #expect(vm.errorMessage != nil)
        #expect(!vm.isLoading)
        await repo.setResult(.success(Catalog(entries: [gameEntry(1), gameEntry(2)])))
        await vm.start()
        #expect(vm.errorMessage == nil)
        #expect(vm.session != nil)
    }

    @Test("leaving discards a late load and resets selection and audio")
    func cancelLoading() async {
        let repo = SuspendedCatalogRepository()
        let vm = makeModel(repository: repo)
        let task = Task { await vm.start() }
        await repo.waitUntilRequested()
        vm.cancel()
        await repo.complete(with: Catalog(entries: [gameEntry(1), gameEntry(2)]))
        await task.value
        #expect(vm.session == nil)
        #expect(vm.selectedPosition == nil)
        #expect(!vm.isLoading)
        #expect(vm.errorMessage == nil)
    }

    @Test("cancelling a task does not publish a game or an error")
    func taskCancellation() async {
        let repo = SuspendedCatalogRepository()
        let vm = makeModel(repository: repo)
        let task = Task { await vm.start() }
        await repo.waitUntilRequested()
        task.cancel()
        await repo.complete(with: Catalog(entries: [gameEntry(1), gameEntry(2)]))
        await task.value
        #expect(vm.session == nil)
        #expect(vm.errorMessage == nil)
        #expect(!vm.isLoading)
    }
}
