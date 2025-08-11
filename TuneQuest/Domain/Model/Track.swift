import Foundation

struct Track: Codable, Equatable, Hashable, Sendable {
    let url: URL
}

extension Track {
    init(dto: TrackDTO) {
        self.url = URL(string: dto.preview)!
    }
}
