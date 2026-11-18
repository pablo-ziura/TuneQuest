import Foundation
import Testing
@testable import TuneQuest

@Suite("CatalogLocalDataSource")
final class CatalogLocalDataSourceTests: @unchecked Sendable {
    @Test("the bundled catalog contains twenty distinct, documented recordings")
    func bundledCatalog() async throws {
        let catalog = try await CatalogLocalDataSource().fetchCatalog()
        #expect(catalog.version == 2)
        #expect(catalog.entries.count == 20)
        #expect(Set(catalog.entries.map(\.id)).count == 20)
        #expect(catalog.entries.allSatisfy {
            !$0.title.isEmpty && !$0.artist.isEmpty && $0.id > 0
                && (1900...2026).contains($0.originalReleaseYear)
                && $0.releaseYearSource.scheme == "https"
        })
        #expect(catalog.entries.first { $0.id == 1109731 }?.originalReleaseYear == 2002)
        #expect(catalog.entries.first { $0.id == 831313 }?.originalReleaseYear == 1982)
    }

    @Test("fetchCatalog returns decoded DTO")
    func fetchCatalogSuccess() async throws {
        let json =
            """
            {
            "version":1,
            "modified":"2025-08-11",
            "entries":[
              {"id":1,"title":"Track 1","artist":"Artist 1","originalReleaseYear":2000,"releaseYearSource":"https://example.com/1"},
              {"id":2,"title":"Track 2","artist":"Artist 2","originalReleaseYear":2000,"releaseYearSource":"https://example.com/2"}
            ]
            }
            """
            .data(using: .utf8)!
        let sut = CatalogLocalDataSource(loader: { json })

        let result = try await sut.fetchCatalog()
        #expect(result == catalogDTOFixture())
    }

    @Test("fetchCatalog propagates errors")
    func fetchCatalogFailure() async {
        enum SampleError: Error { case fail }
        let sut = CatalogLocalDataSource(loader: { throw SampleError.fail })

        var thrown: Error?
        do {
            _ = try await sut.fetchCatalog()
        } catch {
            thrown = error
        }
        #expect(thrown != nil)
    }
}

func catalogDTOFixture() -> CatalogDTO {
    CatalogDTO(version: 1, modified: "2025-08-11", entries: [1, 2].map {
        let entry = gameEntry($0)
        return CatalogEntryDTO(id: entry.id, title: entry.title, artist: entry.artist,
                               originalReleaseYear: entry.originalReleaseYear, releaseYearSource: entry.releaseYearSource)
    })
}
