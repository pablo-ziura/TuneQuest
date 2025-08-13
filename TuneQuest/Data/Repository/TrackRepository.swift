import Foundation

final class TrackRepository: TrackRepositoryProtocol {
    private let service: TrackServiceProtocol

    init(service: TrackServiceProtocol) {
        self.service = service
    }

    func preview(for trackId: Int) async throws -> Track {
        let dto = try await service.fetchTrack(id: trackId)
        return Track(dto: dto)
    }
}
