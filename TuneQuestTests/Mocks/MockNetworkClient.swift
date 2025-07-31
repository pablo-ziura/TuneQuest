import Foundation
@testable import TuneNetwork
@testable import TuneQuest

final actor MockNetworkClient: NetworkClientProtocol, @unchecked Sendable {
    var getCalledWith: String?
    var result: Result<[PostDTO], Error>

    init(result: Result<[PostDTO], Error>) {
        self.result = result
    }

    func get<O: Decodable>(endpoint: String, params: [String: String]?, headers: [String: String]?) async throws -> O {
        getCalledWith = endpoint
        switch result {
        case let .success(value as O):
            return value
        case .success:
            fatalError("Type mismatch")
        case let .failure(error):
            throw error
        }
    }

    func post<O: Decodable>(endpoint: String, params: [String: String]?, headers: [String: String]?, body: Data) async throws -> O {
        fatalError("not implemented")
    }
}
