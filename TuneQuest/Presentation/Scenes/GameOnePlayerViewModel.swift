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

    var lives = 5
    var gameOver = false

    var showAlert = false
    var alertTitle = ""

    init(catalogViewModel: CatalogViewModel, playerManager: AudioPlayerManager) {
        self.catalogViewModel = catalogViewModel
        self.playerManager = playerManager
    }

    func loadInitialTrack() async {
        await catalogViewModel.fetchData()
        remainingIDs = catalogViewModel.catalog?.ids ?? []
        tracks.removeAll()
        lives = 5
        gameOver = false
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
        newCard == nil && !remainingIDs.isEmpty && !gameOver
    }

    private func isTracksInOrder(_ tracks: [Track]) -> Bool {
        let dates = tracks.map { $0.releaseDate ?? $0.album?.releaseDate ?? "" }
        return dates == dates.sorted()
    }

    func finalizeDrop() {
        guard let draggingTrack, !gameOver else { return }
        if isTracksInOrder(tracks) {
            alertTitle = "Great job!"
            newCard = nil
        } else {
            if let index = tracks.firstIndex(of: draggingTrack) {
                tracks.remove(at: index)
            }
            lives -= 1
            if lives > 0 {
                newCard = draggingTrack
                alertTitle = "Wrong order"
            } else {
                newCard = nil
                alertTitle = "Game over"
                gameOver = true
            }
        }
        showAlert = true
        self.draggingTrack = nil
    }
}
