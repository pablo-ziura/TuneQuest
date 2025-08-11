import Foundation

protocol TrackRepositoryProtocol: Sendable {
    func preview(for trackId: Int) async throws -> Track
}
