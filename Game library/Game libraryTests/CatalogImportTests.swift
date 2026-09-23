import XCTest
import SwiftData
@testable import Game_library

@MainActor final class CatalogImportTests: XCTestCase {
    private func container() throws -> ModelContainer {
        try ModelContainer(for: Game.self, CatalogImportProgress.self,
                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    private func response(_ ids: [Int], next: String? = nil) throws -> RAWGSearchResponse {
        let data = try JSONSerialization.data(withJSONObject: ["results": ids.map {
            ["id": $0, "name": "Same name", "slug": "game-\($0)", "rating": 4.8] as [String: Any]
        }])
        let decoded = try JSONDecoder().decode(RAWGSearchResponse.self, from: data)
        return RAWGSearchResponse(next: next, results: decoded.results)
    }

    func testPagesDeduplicateWithoutChangingPersonalOrManualDataAndCanRestart() async throws {
        let store = try container()
        let context = ModelContext(store)
        let manual = Game(title: "Same name")
        manual.isWishlisted = true
        manual.rating = 8
        let existing = Game(title: "Personal title", source: "rawg", externalID: 1)
        existing.isCompleted = true
        existing.isInLibrary = true
        existing.rating = 9
        context.insert(manual)
        context.insert(existing)
        try context.save()
        var requests: [Int] = []
        let importer = CatalogImporter(fetch: { page, _ in
            requests.append(page)
            return try self.response(page == 1 ? [1, 2, 2] : [2, 3], next: page == 1 ? "https://untrusted.invalid/?key=not-followed" : nil)
        }, pause: {})
        await importer.run(container: store, apiKey: "synthetic")
        XCTAssertEqual(requests, [1, 2])
        XCTAssertNil(importer.errorMessage)
        XCTAssertFalse(importer.isRunning)
        let reopened = ModelContext(store)
        let games = try reopened.fetch(FetchDescriptor<Game>())
        XCTAssertEqual(games.count, 4)
        let imported = games.filter { $0.externalID == 2 || $0.externalID == 3 }
        for game in imported {
            XCTAssertNil(game.rating)
            XCTAssertTrue(GamePresentation.statusLabels(for: game).isEmpty)
            XCTAssertTrue(LibraryTab.allGames.includes(game))
            XCTAssertEqual(game.sourceURL, "https://rawg.io/games/game-\(game.externalID!)")
        }
        let saved = try XCTUnwrap(games.first { $0.externalID == 1 })
        XCTAssertEqual(saved.title, "Personal title")
        XCTAssertEqual(saved.rating, 9)
        XCTAssertTrue(saved.isCompleted && saved.isInLibrary)
        XCTAssertFalse(saved.isPlayed)
        XCTAssertEqual(games.first { $0.source == "manual" }?.rating, 8)
        XCTAssertTrue(games.first { $0.source == "manual" }!.isWishlisted)
        let progress = try XCTUnwrap(reopened.fetch(FetchDescriptor<CatalogImportProgress>()).first)
        XCTAssertTrue(progress.isComplete)
        XCTAssertEqual(progress.importedCount, 2)
        await importer.run(container: store, apiKey: "synthetic", restart: true)
        XCTAssertEqual(requests, [1, 2, 1, 2])
        XCTAssertEqual(try ModelContext(store).fetchCount(FetchDescriptor<Game>()), 4)
        XCTAssertEqual(try ModelContext(store).fetch(FetchDescriptor<Game>()).first { $0.externalID == 1 }?.rating, 9)
    }

    func testQuotaStopsAndNewInstanceResumesFailedPage() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let config = ModelConfiguration(url: directory.appendingPathComponent("games.store"))
        var requests: [Int] = []
        do {
            let store = try ModelContainer(for: Game.self, CatalogImportProgress.self, configurations: config)
            let importer = CatalogImporter(fetch: { page, _ in
                requests.append(page)
                if page == 2 { throw RAWGServiceError.rateLimited }
                return try self.response([1], next: "next")
            }, pause: {})
            await importer.run(container: store, apiKey: "synthetic")
            XCTAssertEqual(requests, [1, 2])
            XCTAssertEqual(importer.errorMessage, RAWGServiceError.rateLimited.errorDescription)
            let progress = try XCTUnwrap(ModelContext(store).fetch(FetchDescriptor<CatalogImportProgress>()).first)
            XCTAssertEqual(progress.nextPage, 2)
            XCTAssertFalse(progress.isComplete)
        }
        let reopened = try ModelContainer(for: Game.self, CatalogImportProgress.self, configurations: config)
        let resumed = CatalogImporter(fetch: { page, _ in
            requests.append(page)
            return try self.response([1, 2])
        }, pause: {})
        await resumed.run(container: reopened, apiKey: "new-key")
        XCTAssertEqual(requests, [1, 2, 2])
        XCTAssertEqual(try ModelContext(reopened).fetchCount(FetchDescriptor<Game>()), 2)
        XCTAssertNil(resumed.errorMessage)
    }

    func testFailedPageSaveRollsBackGamesAndCheckpointOnly() async throws {
        let store = try container()
        let editor = ModelContext(store)
        let manual = Game(title: "Manual")
        editor.insert(manual)
        try editor.save()
        editor.autosaveEnabled = false
        manual.title = "Unsaved user edit"
        var saves = 0
        let importer = CatalogImporter(fetch: { page, _ in
            try self.response([page], next: "next")
        }, pause: {}, save: { context in
            saves += 1
            if saves == 2 { throw CocoaError(.fileWriteUnknown) }
            try context.save()
        })
        await importer.run(container: store, apiKey: "synthetic")
        XCTAssertNotNil(importer.errorMessage)
        XCTAssertEqual(saves, 2)
        XCTAssertEqual(manual.title, "Unsaved user edit")
        let inspection = ModelContext(store)
        XCTAssertEqual(try inspection.fetchCount(FetchDescriptor<Game>()), 2)
        XCTAssertEqual(try inspection.fetch(FetchDescriptor<Game>()).compactMap(\.externalID), [1])
        XCTAssertEqual(try inspection.fetch(FetchDescriptor<CatalogImportProgress>()).first?.nextPage, 2)
        let retry = CatalogImporter(fetch: { page, _ in
            XCTAssertEqual(page, 2)
            return try self.response([page])
        }, pause: {})
        await retry.run(container: store, apiKey: "synthetic")
        XCTAssertNil(retry.errorMessage)
        XCTAssertEqual(try ModelContext(store).fetchCount(FetchDescriptor<Game>()), 3)
    }

    func testMissingKeyAndNetworkErrorsNeverRetryAutomatically() async throws {
        let store = try container()
        var calls = 0
        let missing = CatalogImporter(fetch: { _, _ in calls += 1; return try self.response([]) }, pause: {})
        await missing.run(container: store, apiKey: " ")
        XCTAssertEqual(calls, 0)
        XCTAssertEqual(missing.errorMessage, RAWGServiceError.missingKey.errorDescription)
        for error in [RAWGServiceError.unauthorized, .rateLimited, .offline, .timedOut, .invalidResponse, .serverError] {
            calls = 0
            let importer = CatalogImporter(fetch: { _, _ in calls += 1; throw error }, pause: {})
            await importer.run(container: store, apiKey: "synthetic-secret")
            XCTAssertEqual(calls, 1)
            XCTAssertEqual(importer.errorMessage, error.errorDescription)
            XCTAssertFalse(importer.errorMessage!.contains("synthetic-secret"))
        }
        XCTAssertEqual(try ModelContext(store).fetchCount(FetchDescriptor<Game>()), 0)
    }

    func testPageLimitAndMalformedEmptyPageStopWithoutSkipping() async throws {
        let store = try container()
        var pages: [Int] = []
        let importer = CatalogImporter(pageLimit: 2, fetch: { page, _ in
            pages.append(page)
            return try self.response([page], next: "next")
        }, pause: {})
        await importer.run(container: store, apiKey: "synthetic")
        XCTAssertEqual(pages, [1, 2])
        XCTAssertNil(importer.errorMessage)
        let invalid = CatalogImporter(fetch: { page, _ in
            XCTAssertEqual(page, 3)
            return try self.response([], next: "next")
        }, pause: {})
        await invalid.run(container: store, apiKey: "synthetic")
        XCTAssertEqual(invalid.errorMessage, RAWGServiceError.invalidResponse.errorDescription)
        XCTAssertEqual(try ModelContext(store).fetch(FetchDescriptor<CatalogImportProgress>()).first?.nextPage, 3)
    }

    func testStopAndOverlappingRunDoNotCommitLateResponse() async throws {
        let store = try container()
        var continuation: CheckedContinuation<RAWGSearchResponse, Error>?
        var calls = 0
        let importer = CatalogImporter(fetch: { _, _ in
            calls += 1
            return try await withCheckedThrowingContinuation { continuation = $0 }
        }, pause: {})
        let first = Task { await importer.run(container: store, apiKey: "synthetic") }
        while continuation == nil { await Task.yield() }
        await importer.run(container: store, apiKey: "synthetic")
        XCTAssertEqual(calls, 1)
        importer.stop()
        continuation?.resume(returning: try response([1]))
        await first.value
        XCTAssertFalse(importer.isRunning)
        XCTAssertNil(importer.errorMessage)
        XCTAssertEqual(try ModelContext(store).fetchCount(FetchDescriptor<Game>()), 0)
        XCTAssertEqual(try ModelContext(store).fetchCount(FetchDescriptor<CatalogImportProgress>()), 0)
    }

    func testCancellationBetweenPagesRetainsLastCommittedPage() async throws {
        let store = try container()
        var calls = 0
        let importer = CatalogImporter(fetch: { _, _ in
            calls += 1
            return try self.response([1], next: "next")
        }, pause: { throw CancellationError() })
        await importer.run(container: store, apiKey: "synthetic")
        XCTAssertEqual(calls, 1)
        XCTAssertNil(importer.errorMessage)
        XCTAssertEqual(try ModelContext(store).fetchCount(FetchDescriptor<Game>()), 1)
        XCTAssertEqual(try ModelContext(store).fetch(FetchDescriptor<CatalogImportProgress>()).first?.nextPage, 2)
    }

    func testCurrentLibraryMigratesToProgressSchemaWithoutLosingRatings() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("games.store")
        do {
            let old = try ModelContainer(for: Game.self, configurations: ModelConfiguration(url: url))
            let context = ModelContext(old)
            let game = Game(title: "Saved", source: "rawg", externalID: 44,
                            sourceURL: "https://rawg.io/games/saved")
            game.rating = 7
            game.isWishlisted = true
            context.insert(game)
            try context.save()
        }
        let migrated = try ModelContainer(for: Game.self, CatalogImportProgress.self,
                                          configurations: ModelConfiguration(url: url))
        let context = ModelContext(migrated)
        let game = try XCTUnwrap(context.fetch(FetchDescriptor<Game>()).first)
        XCTAssertEqual(game.title, "Saved")
        XCTAssertEqual(game.rating, 7)
        XCTAssertTrue(game.isWishlisted)
        XCTAssertEqual(game.externalID, 44)
        XCTAssertEqual(game.sourceURL, "https://rawg.io/games/saved")
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CatalogImportProgress>()), 0)
    }
}
