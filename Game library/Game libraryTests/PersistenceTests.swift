import XCTest
import SwiftData
@testable import Game_library

@MainActor final class PersistenceTests: XCTestCase {
    func testTabsDependOnlyOnTheirIndependentStatus() {
        let game = Game(title: "Tabs")
        XCTAssertEqual(LibraryTab.allCases.count, 4)
        for mask in 0..<32 {
            game.isInLibrary = mask & 1 != 0
            game.isWishlisted = mask & 2 != 0
            game.isToPlay = mask & 4 != 0
            game.isPlayed = mask & 8 != 0
            game.isCompleted = mask & 16 != 0
            game.rating = 9
            XCTAssertTrue(LibraryTab.allGames.includes(game))
            XCTAssertEqual(LibraryTab.library.includes(game), game.isInLibrary)
            XCTAssertEqual(LibraryTab.wishlist.includes(game), game.isWishlisted)
            XCTAssertEqual(LibraryTab.toPlay.includes(game), game.isToPlay)
        }
    }

    func testFailedEditsRestoreOnlyTheirFieldAndCanRetry() throws {
        let container = try ModelContainer(for: Game.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let game = Game(title: "Original")
        game.rating = 8
        context.insert(game)
        try context.save()
        game.isToPlay = true // Başka bir bekleyen değişiklik geri alınmamalı.
        let fail: () throws -> Void = { throw CocoaError(.fileWriteUnknown) }
        let expected = GameMutation.Outcome.saveFailed(message: GamePresentation.saveFailedMessage)
        XCTAssertEqual(GameMutation.rename(game, rawTitle: "Changed", save: fail), expected)
        XCTAssertEqual(GameMutation.setRating(game, raw: nil, save: fail), expected)
        for key in [\Game.isInLibrary, \Game.isWishlisted, \Game.isPlayed, \Game.isCompleted] {
            XCTAssertEqual(GameMutation.setStatus(game, keyPath: key, value: true, save: fail), expected)
            XCTAssertFalse(game[keyPath: key])
        }
        XCTAssertEqual(game.title, "Original")
        XCTAssertEqual(game.rating, 8)
        XCTAssertTrue(game.isToPlay)
        XCTAssertEqual(GameMutation.setRating(game, raw: 10, save: context.save), .applied)
        let saved = try XCTUnwrap(ModelContext(container).fetch(FetchDescriptor<Game>()).first)
        XCTAssertEqual(saved.title, "Original")
        XCTAssertEqual(saved.rating, 10)
        XCTAssertTrue(saved.isToPlay)
        XCTAssertFalse(saved.isCompleted)
    }

    func testDiskReopenPreservesMixedRecordsAndOfflineEdits() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let config = ModelConfiguration(url: directory.appendingPathComponent("games.store"))
        // Ayrı Core Data koordinatörlerindeki nesne eşitliği yerine kalıcı kimlik içeriğini karşılaştır.
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        var identities: [String: Data] = [:]
        do {
            let container = try ModelContainer(for: Game.self, configurations: config)
            let context = ModelContext(container)
            let catalog = try JSONDecoder().decode(RAWGGame.self, from: Data(#"{"id":42,"name":"Portal","slug":"portal","released":"2007-10-10","platforms":[{"platform":{"name":"PC"}}]}"#.utf8))
            guard case .added(let manual) = try Game.add(GameDraft.manual("Manual"), to: context),
                  case .added(let imported) = try Game.add(GameDraft.rawg(catalog), to: context) else { return XCTFail() }
            manual.isWishlisted = true
            manual.rating = 1
            imported.isInLibrary = true
            imported.isToPlay = true
            imported.isPlayed = true
            imported.isCompleted = true
            imported.rating = 10
            try context.save()
            identities = [manual.title: try encoder.encode(manual.persistentModelID), imported.title: try encoder.encode(imported.persistentModelID)]
        }
        do {
            let container = try ModelContainer(for: Game.self, configurations: config)
            let context = ModelContext(container)
            let games = try context.fetch(FetchDescriptor<Game>())
            XCTAssertEqual(games.count, 2)
            for game in games { XCTAssertEqual(try encoder.encode(game.persistentModelID), identities[game.title]) }
            let imported = try XCTUnwrap(games.first { $0.source == "rawg" })
            let manual = try XCTUnwrap(games.first { $0.source == "manual" })
            XCTAssertTrue(manual.isWishlisted)
            XCTAssertEqual(manual.rating, 1)
            XCTAssertEqual(imported.externalID, 42)
            XCTAssertEqual(imported.platforms, ["PC"])
            XCTAssertEqual(imported.releaseDate, "2007-10-10")
            XCTAssertEqual(imported.sourceURL, "https://rawg.io/games/portal")
            XCTAssertEqual(imported.rating, 10)
            XCTAssertTrue(imported.isInLibrary && imported.isToPlay && imported.isPlayed && imported.isCompleted)
            XCTAssertFalse(imported.isWishlisted)
            // Yerel düzenlemelerin ağ servisine veya anahtara bağımlılığı yoktur.
            XCTAssertEqual(GameMutation.rename(imported, rawTitle: "Offline Portal", save: context.save), .applied)
            XCTAssertEqual(GameMutation.setRating(imported, raw: nil, save: context.save), .applied)
            XCTAssertEqual(GameMutation.setStatus(imported, keyPath: \Game.isToPlay, value: false, save: context.save), .applied)
        }
        let reopened = try ModelContainer(for: Game.self, configurations: config)
        let games = try ModelContext(reopened).fetch(FetchDescriptor<Game>())
        let imported = try XCTUnwrap(games.first { $0.externalID == 42 })
        XCTAssertEqual(try encoder.encode(imported.persistentModelID), identities["Portal"])
        XCTAssertEqual(imported.title, "Offline Portal")
        XCTAssertNil(imported.rating)
        XCTAssertFalse(imported.isToPlay)
        XCTAssertTrue(imported.isInLibrary && imported.isPlayed && imported.isCompleted)
        XCTAssertEqual(games.first { $0.source == "manual" }?.title, "Manual")
    }
}
