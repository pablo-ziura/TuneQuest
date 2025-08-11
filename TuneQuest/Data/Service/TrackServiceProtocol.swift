import Foundation

protocol TrackServiceProtocol: Sendable {
    func fetchTrack(id: Int) async throws -> TrackDTO
}
