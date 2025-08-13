//
//  MockCatalogRepository.swift
//  TuneQuest
//
//  Created by Pablo Ruiz Arnal on 12/8/25.
//


import Foundation
@testable import TuneQuest

final actor MockCatalogRepository: CatalogRepositoryProtocol, @unchecked Sendable {
    var result: Result<Catalog, Error>

    init(result: Result<Catalog, Error>) {
        self.result = result
    }

    func fetchCatalog() async throws -> Catalog {
        switch result {
        case let .success(value):
            return value
        case let .failure(error):
            throw error
        }
    }
}