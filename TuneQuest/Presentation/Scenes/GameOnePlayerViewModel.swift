import SwiftUI

@MainActor
@Observable
final class GameOnePlayerViewModel {
    @ObservationIgnored private let catalogViewModel: CatalogViewModel
    @ObservationIgnored private let playerManager: AudioPlayerManager

    var tracks: [Track] = []
    var draggingTrack: Track?
    var newCard: Track?
    private var remainingIDs: [Int] = []

    init(catalogViewModel: CatalogViewModel, playerManager: AudioPlayerManager) {
        self.catalogViewModel = catalogViewModel
        self.playerManager = playerManager
    }

    func loadInitialTrack() async {
        await catalogViewModel.fetchData()
        remainingIDs = catalogViewModel.catalog?.ids ?? []
        tracks.removeAll()
        if let track = await randomTrack() {
            tracks.append(track)
        }
    }

    func addNewCard() async {
        newCard = await randomTrack()
    }

    private func randomTrack() async -> Track? {
        guard !remainingIDs.isEmpty else { return nil }
        let index = Int.random(in: 0..<remainingIDs.count)
        let id = remainingIDs.remove(at: index)
        return await playerManager.trackInfo(for: id)
    }

    var canAddCard: Bool {
        newCard == nil && !remainingIDs.isEmpty
    }

    func resetDragState() {
        draggingTrack = nil
        newCard = nil
    }
}
