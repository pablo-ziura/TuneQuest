import Foundation

struct GetTrackPreviewUseCase {
    private let repository: TrackRepositoryProtocol

    init(repository: TrackRepositoryProtocol) {
        self.repository = repository
    }

    func execute(trackId: Int) async throws -> Track {
        try await repository.preview(for: trackId)
    }
}
