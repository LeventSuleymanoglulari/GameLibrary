import XCTest
@testable import Game_library

final class Game_libraryTests: XCTestCase {
    func testMalformedOptionalMetadataDoesNotDiscardGame() throws {
        let data = Data(#"{"id":42,"name":"Portal","released":12,"slug":[],"platforms":[{"platform":{"name":"PC"}},{"platform":null}]}"#.utf8)
        let game = try JSONDecoder().decode(RAWGGame.self, from: data)
        XCTAssertEqual(game.id, 42)
        XCTAssertEqual(game.platformNames, ["PC"])
        XCTAssertNil(game.released)
    }
}
