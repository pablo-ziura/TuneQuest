import Foundation
import Testing
@testable import TuneQuest

func gameEntry(_ id: Int, year: Int = 2000) -> CatalogEntry {
    CatalogEntry(id: id, title: "Track \(id)", artist: "Artist \(id)",
                 originalReleaseYear: year, releaseYearSource: URL(string: "https://example.com/\(id)")!)
}

@Suite("GameSession")
struct GameSessionTests {
    @Test("placements at either end and between tracks keep the timeline sorted")
    func sortedPlacements() throws {
        var game = try GameSession(tracks: [gameEntry(1, year: 1980), gameEntry(2, year: 1970),
                                           gameEntry(3, year: 1990), gameEntry(4, year: 1985)],
                                   configuration: .init(targetCorrectPlacements: 3))
        for position in [0, 2, 2] {
            game.confirm(at: position)
            game.advance()
        }
        #expect(game.phase == .won)
        #expect(game.correctPlacements == 3)
        #expect(game.timeline.map(\.originalReleaseYear) == [1970, 1980, 1985, 1990])
        #expect(game.remainingLives == 3)
    }

    @Test("equal years accept all chronologically valid gaps", arguments: [0, 1, 2])
    func equalYears(position: Int) throws {
        var game = try GameSession(tracks: (1...3).map { gameEntry($0) },
                                   configuration: .init(targetCorrectPlacements: 2))
        game.confirm(at: 1)
        game.advance()
        game.confirm(at: position)
        #expect(game.phase == .won)
    }

    @Test("a failed placement keeps the song and costs exactly one life per confirmed attempt")
    func retryAndLoss() throws {
        var game = try GameSession(tracks: [gameEntry(1, year: 1980), gameEntry(2, year: 1990)],
                                   configuration: .init(targetCorrectPlacements: 1))
        for lives in [2, 1, 0] {
            game.confirm(at: 0)
            game.confirm(at: 0)
            #expect(game.remainingLives == lives)
            #expect(game.timeline.count == 1)
            #expect(game.pendingTrack.id == 2)
            #expect(game.correctPlacements == 0)
            game.advance()
        }
        #expect(game.phase == .lost)
        #expect(game.correctPosition == 1)
        game.confirm(at: 1)
        #expect(game.phase == .lost)
    }

    @Test("a successful retry counts once and the tenth correct answer wins")
    func defaultVictory() throws {
        var game = try GameSession(tracks: (1...11).map { gameEntry($0, year: 1970 + $0) })
        game.confirm(at: 0)
        game.advance()
        for _ in 0..<10 {
            game.confirm(at: game.timeline.count)
            let snapshot = game
            game.confirm(at: game.timeline.count)
            #expect(game == snapshot)
            game.advance()
        }
        #expect(game.phase == .won)
        #expect(game.correctPlacements == 10)
        #expect(game.remainingLives == 2)
        #expect(game.timeline.count == 11)
    }

    @Test("out of range positions and invalid state transitions have no effect")
    func invalidActions() throws {
        var game = try GameSession(tracks: [gameEntry(1), gameEntry(2)],
                                   configuration: .init(targetCorrectPlacements: 1))
        let initial = game
        game.confirm(at: -1)
        game.confirm(at: 2)
        game.advance()
        #expect(game == initial)
    }

    @Test("invalid setup is rejected")
    func invalidSetup() {
        #expect(throws: GameSessionError.invalidConfiguration) {
            try GameSession(tracks: [], configuration: .init(startingLives: 0))
        }
        #expect(throws: GameSessionError.insufficientTracks) { try GameSession(tracks: []) }
        #expect(throws: GameSessionError.invalidCatalog) {
            try GameSession(tracks: [gameEntry(1), gameEntry(1)], configuration: .init(targetCorrectPlacements: 1))
        }
    }
}
