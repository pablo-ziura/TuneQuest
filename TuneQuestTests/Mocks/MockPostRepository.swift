import Foundation
@testable import TuneNetwork
@testable import TuneQuest

final actor MockPostRepository: PostRepositoryProtocol, @unchecked Sendable {
    var result: Result<[Post], Error>

    init(result: Result<[Post], Error>) {
        self.result = result
    }

    func posts() async throws -> [Post] {
        switch result {
        case let .success(value):
            return value
        case let .failure(error):
            throw error
        }
    }
}
