import Foundation
@testable import TuneQuest

final actor MockPostService: PostServiceProtocol, @unchecked Sendable {
    var result: Result<[PostDTO], Error>

    init(result: Result<[PostDTO], Error>) {
        self.result = result
    }

    func fetchPosts() async throws -> [PostDTO] {
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}
