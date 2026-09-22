import XCTest
import SwiftData
import Synchronization
@testable import Game_library

@MainActor final class Game_libraryTests: XCTestCase {
    func testMalformedOptionalMetadataDoesNotDiscardGame() throws {
        let data = Data(#"{"id":42,"name":"Portal","released":12,"slug":[],"platforms":[{"platform":{"name":"PC"}},{"platform":null}]}"#.utf8)
        let game = try JSONDecoder().decode(RAWGGame.self, from: data)
        XCTAssertEqual(game.id, 42)
        XCTAssertEqual(game.platformNames, ["PC"])
        XCTAssertNil(game.released)
    }

    func testHostAndCredentialsUseOnlyMemoryStorage() throws {
        guard Game_libraryApp.usesTestStorage else { return XCTFail("Hosted tests must use isolated storage") }
        let app = Game_libraryApp()
        XCTAssertTrue(app.sharedModelContainer.configurations.allSatisfy(\.isStoredInMemoryOnly))
        XCTAssertNil(try KeychainStore.loadRAWGKey())
        try KeychainStore.saveRAWGKey("memory-only-test-key")
        XCTAssertEqual(try KeychainStore.loadRAWGKey(), "memory-only-test-key")
    }

    private func catalog(_ id: Int = 42, name: String = "Portal") throws -> RAWGGame {
        try JSONDecoder().decode(RAWGGame.self, from: JSONSerialization.data(withJSONObject: ["id": id, "name": name]))
    }

    func testInvalidIdentityAndUnsafeLinks() throws {
        XCTAssertThrowsError(try catalog(0))
        XCTAssertThrowsError(try catalog(1, name: "  "))
        XCTAssertThrowsError(try GameDraft.manual(" \n "))
        for url in ["http://rawg.io/games/test", "https://rawg.io.evil.test/", "https://user@rawg.io/", "javascript:alert(1)"] {
            XCTAssertEqual(RAWGService.safeSourceURL(url), RAWGService.attributionURL)
        }
        XCTAssertEqual(try catalog().sourceURL, RAWGService.attributionURL)
    }

    func testDurableIdentityNameConfirmationAndFailedSave() throws {
        let container = try ModelContainer(for: Game.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let manual = try GameDraft.manual("  Portal  ")
        guard case .added(let original) = try Game.add(manual, to: context) else { return XCTFail("Expected insert") }
        original.isWishlisted = true
        try context.save()
        let draft = try GameDraft.rawg(catalog())
        guard case .sameName(let matches) = try Game.add(draft, to: context) else { return XCTFail("Expected name confirmation") }
        XCTAssertEqual(matches.map(\.persistentModelID), [original.persistentModelID])
        guard case .added(let imported) = try Game.add(draft, to: context, allowSameName: true) else { return XCTFail("Expected separate record") }
        imported.isInLibrary = true
        try context.save()
        let second = ModelContext(container)
        guard case .existing(let existing) = try Game.add(draft, to: second) else { return XCTFail("Expected existing identity") }
        XCTAssertEqual(existing.persistentModelID, imported.persistentModelID)
        XCTAssertTrue(existing.isInLibrary)
        XCTAssertEqual(try second.fetchCount(FetchDescriptor<Game>()), 2)
        original.title = "Pending unrelated edit"
        XCTAssertThrowsError(try Game.add(GameDraft.manual("Failed"), to: context, save: { throw URLError(.cannotWriteToFile) }))
        XCTAssertEqual(original.title, "Pending unrelated edit")
        XCTAssertEqual(try context.fetch(FetchDescriptor<Game>()).map(\.title).filter { $0 == "Failed" }.count, 0)
        XCTAssertEqual(manual.title, "Portal")
    }

    func testIndependentStatusesAndOptionalRatingPersistTogether() throws {
        let container = try ModelContainer(for: Game.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let game = Game(title: "Hades")
        game.isInLibrary = true
        game.isToPlay = true
        game.isCompleted = true
        game.rating = 9
        context.insert(game)
        try context.save()

        let reopened = ModelContext(container)
        let saved = try XCTUnwrap(reopened.fetch(FetchDescriptor<Game>()).first)
        XCTAssertTrue(saved.isInLibrary)
        XCTAssertTrue(saved.isToPlay)
        XCTAssertTrue(saved.isCompleted)
        XCTAssertFalse(saved.isWishlisted)
        XCTAssertFalse(saved.isPlayed)
        XCTAssertEqual(saved.rating, 9)
        XCTAssertEqual(GamePresentation.statusLabels(for: saved), ["Kütüphane", "Oynanacak", "Bitti"])
        saved.isCompleted = true
        XCTAssertFalse(saved.isPlayed)
        saved.rating = nil
        try reopened.save()
        XCTAssertNil(try XCTUnwrap(ModelContext(container).fetch(FetchDescriptor<Game>()).first).rating)
    }

    func testTitleAndRatingMutationsRejectOrApply() throws {
        let container = try ModelContainer(for: Game.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let game = Game(title: "Celeste")
        game.rating = 8
        context.insert(game)
        try context.save()

        switch GameMutation.rename(game, rawTitle: "  \n  ", save: context.save) {
        case .rejected(let message):
            XCTAssertEqual(message, GamePresentation.emptyTitleMessage)
        default:
            XCTFail("Expected rename rejection")
        }
        XCTAssertEqual(game.title, "Celeste")

        switch GameMutation.manualDraft(from: " \t ") {
        case .rejected(let message):
            XCTAssertEqual(message, GamePresentation.emptyTitleMessage)
        case .ok:
            XCTFail("Expected manualDraft rejection")
        }

        switch GameMutation.setRating(game, raw: 0, save: context.save) {
        case .rejected(let message):
            XCTAssertEqual(message, GamePresentation.ratingOutOfScaleMessage)
        default:
            XCTFail("Expected setRating(0) rejection")
        }
        XCTAssertEqual(game.rating, 8)

        switch GameMutation.setRating(game, raw: 11, save: context.save) {
        case .rejected(let message):
            XCTAssertEqual(message, GamePresentation.ratingOutOfScaleMessage)
        default:
            XCTFail("Expected setRating(11) rejection")
        }
        XCTAssertEqual(game.rating, 8)

        switch GameMutation.setRating(game, raw: 9, save: context.save) {
        case .applied:
            break
        default:
            XCTFail("Expected setRating(9) to apply")
        }
        XCTAssertEqual(game.rating, 9)

        switch GameMutation.setRating(game, raw: nil, save: context.save) {
        case .applied:
            break
        default:
            XCTFail("Expected setRating(nil) to clear")
        }
        XCTAssertNil(game.rating)
    }

    func testSearchSnapshotsQueryDeduplicatesAndRetriesFailedPage() async throws {
        var requests: [(String, Int)] = []
        var failSecond = true
        let game = try catalog()
        let search = CatalogSearchSession { query, page, _ in
            requests.append((query, page))
            if page == 2 && failSecond { failSecond = false; throw URLError(.timedOut) }
            return RAWGSearchResponse(next: page == 1 ? "next" : nil, results: [game])
        }
        await search.search("  Portal  ", apiKey: "test")
        await search.loadNext(apiKey: "test")
        XCTAssertNotNil(search.errorMessage)
        XCTAssertEqual(search.results.count, 1)
        await search.retry(apiKey: "test")
        XCTAssertEqual(requests.map { $0.0 }, ["Portal", "Portal", "Portal"])
        XCTAssertEqual(requests.map { $0.1 }, [1, 2, 2])
        XCTAssertEqual(search.results.count, 1)
        XCTAssertFalse(search.hasNextPage)
        XCTAssertNil(search.errorMessage)
    }

    func testOverlappingSearchIsIgnoredAndResetFailureClearsPagination() async throws {
        var continuation: CheckedContinuation<RAWGSearchResponse, Error>?
        var calls = 0
        let search = CatalogSearchSession { _, _, _ in
            calls += 1
            return try await withCheckedThrowingContinuation { continuation = $0 }
        }
        let first = Task { await search.search("First", apiKey: "test") }
        while continuation == nil { await Task.yield() }
        await search.search("Second", apiKey: "test")
        XCTAssertEqual(calls, 1)
        continuation?.resume(returning: RAWGSearchResponse(next: "next", results: [try catalog()]))
        await first.value
        continuation = nil
        let second = Task { await search.search("New", apiKey: "test") }
        while continuation == nil { await Task.yield() }
        continuation?.resume(throwing: URLError(.notConnectedToInternet))
        await second.value
        XCTAssertEqual(search.query, "New")
        XCTAssertTrue(search.results.isEmpty)
        XCTAssertFalse(search.hasNextPage)
    }

    func testDiskStoreReopensImportedMetadata() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let configuration = ModelConfiguration(url: directory.appendingPathComponent("games.store"))
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        var identifier: Data?
        do {
            let container = try ModelContainer(for: Game.self, configurations: configuration)
            let context = ModelContext(container)
            guard case .added(let game) = try Game.add(GameDraft.rawg(catalog()), to: context) else { return XCTFail() }
            identifier = try encoder.encode(game.persistentModelID)
        }
        let reopened = try ModelContainer(for: Game.self, configurations: configuration)
        let games = try ModelContext(reopened).fetch(FetchDescriptor<Game>())
        XCTAssertEqual(games.count, 1)
        XCTAssertEqual(try encoder.encode(XCTUnwrap(games.first).persistentModelID), identifier)
        XCTAssertEqual(games.first?.source, "rawg")
        XCTAssertEqual(games.first?.externalID, 42)
        XCTAssertEqual(games.first?.sourceURL, RAWGService.attributionURL.absoluteString)
        XCTAssertEqual(games.first?.platforms, [])
    }

    func testTransportParametersAndErrorClassification() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CatalogURLProtocol.self]
        let service = RAWGService(session: URLSession(configuration: configuration))
        CatalogURLProtocol.status = 200
        let response = try await service.search(query: "A & B", page: 2, apiKey: "fixture")
        XCTAssertTrue(response.results.isEmpty)
        let items = URLComponents(url: try XCTUnwrap(CatalogURLProtocol.requestURL), resolvingAgainstBaseURL: false)?.queryItems
        XCTAssertEqual(items?.first { $0.name == "search" }?.value, "A & B")
        XCTAssertEqual(items?.first { $0.name == "page" }?.value, "2")
        XCTAssertEqual(items?.first { $0.name == "page_size" }?.value, "20")
        for status in [401, 403, 429, 500] {
            CatalogURLProtocol.status = status
            do {
                _ = try await service.search(query: "Portal", page: 1, apiKey: "fixture")
                XCTFail("Expected HTTP failure")
            } catch let error as RAWGServiceError {
                switch (status, error) {
                case (401, .unauthorized), (403, .unauthorized), (429, .rateLimited), (500, .serverError): break
                default: XCTFail("Incorrect classification")
                }
            }
        }
        do { _ = try await service.search(query: "Portal", page: 1, apiKey: " "); XCTFail() }
        catch RAWGServiceError.missingKey { }
    }
}

private final class CatalogURLProtocol: URLProtocol, @unchecked Sendable {
    private static let state = Mutex((status: 200, requestURL: URL?.none))
    static var status: Int {
        get { state.withLock { $0.status } }
        set { state.withLock { $0.status = newValue } }
    }
    static var requestURL: URL? {
        get { state.withLock { $0.requestURL } }
        set { state.withLock { $0.requestURL = newValue } }
    }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.requestURL = request.url
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(#"{"next":null,"results":[]}"#.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() { }
}
