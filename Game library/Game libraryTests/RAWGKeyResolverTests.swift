import XCTest
@testable import Game_library

final class RAWGKeyResolverTests: XCTestCase {
    func testKeychainValueReplacesBuildSecret() {
        XCTAssertEqual(
            RAWGKeyResolver.resolve(keychainKey: " stored ", buildSecret: "baked"),
            "stored"
        )
    }

    func testBlankKeychainUsesTrimmedBuildSecret() {
        XCTAssertEqual(
            RAWGKeyResolver.resolve(keychainKey: "   ", buildSecret: " baked "),
            "baked"
        )
        XCTAssertEqual(
            RAWGKeyResolver.resolve(keychainKey: nil, buildSecret: " baked "),
            "baked"
        )
    }

    func testBlankInputsStayEmpty() {
        XCTAssertEqual(
            RAWGKeyResolver.resolve(keychainKey: nil, buildSecret: "  "),
            ""
        )
    }
}
