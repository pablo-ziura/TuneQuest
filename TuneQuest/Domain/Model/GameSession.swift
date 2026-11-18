import Foundation

struct GameConfiguration: Equatable, Sendable {
    var startingLives = 3
    var targetCorrectPlacements = 10
}

enum GameSessionError: Error, Equatable {
    case invalidConfiguration
    case invalidCatalog
    case insufficientTracks
}

enum GamePhase: Equatable, Sendable {
    case placing
    case correct
    case incorrect
    case won
    case lost

    var isFinished: Bool { self == .won || self == .lost }
}

/// A value-type state machine. Only confirmed placements can change the timeline or lives.
struct GameSession: Equatable, Sendable {
    let configuration: GameConfiguration
    private(set) var timeline: [CatalogEntry]
    private(set) var pendingTrack: CatalogEntry
    private(set) var remainingLives: Int
    private(set) var correctPlacements = 0
    private(set) var phase: GamePhase = .placing
    private var remainingTracks: [CatalogEntry]

    init(tracks: [CatalogEntry], configuration: GameConfiguration = .init()) throws {
        guard configuration.startingLives > 0,
              configuration.targetCorrectPlacements > 0,
              configuration.targetCorrectPlacements < Int.max else {
            throw GameSessionError.invalidConfiguration
        }
        guard tracks.count >= configuration.targetCorrectPlacements + 1 else {
            throw GameSessionError.insufficientTracks
        }
        guard Set(tracks.map(\.id)).count == tracks.count else {
            throw GameSessionError.invalidCatalog
        }
        self.configuration = configuration
        timeline = [tracks[0]]
        pendingTrack = tracks[1]
        remainingTracks = Array(tracks.dropFirst(2).prefix(configuration.targetCorrectPlacements - 1))
        remainingLives = configuration.startingLives
    }

    func isValidPosition(_ index: Int) -> Bool {
        guard (0...timeline.count).contains(index) else { return false }
        let year = pendingTrack.originalReleaseYear
        return (index == 0 || timeline[index - 1].originalReleaseYear <= year)
            && (index == timeline.count || year <= timeline[index].originalReleaseYear)
    }

    /// One valid position, including the first position within a group of equal years.
    var correctPosition: Int {
        timeline.firstIndex { $0.originalReleaseYear >= pendingTrack.originalReleaseYear } ?? timeline.count
    }

    mutating func confirm(at index: Int) {
        guard phase == .placing, (0...timeline.count).contains(index) else { return }
        if isValidPosition(index) {
            timeline.insert(pendingTrack, at: index)
            correctPlacements += 1
            phase = correctPlacements == configuration.targetCorrectPlacements ? .won : .correct
        } else {
            remainingLives -= 1
            phase = remainingLives == 0 ? .lost : .incorrect
        }
    }

    mutating func advance() {
        switch phase {
        case .correct:
            guard !remainingTracks.isEmpty else { return }
            pendingTrack = remainingTracks.removeFirst()
            phase = .placing
        case .incorrect:
            phase = .placing
        default:
            break
        }
    }
}
