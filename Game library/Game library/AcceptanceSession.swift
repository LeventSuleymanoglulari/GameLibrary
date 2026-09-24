import Foundation

struct AcceptanceSession: Equatable {
    let id: UUID

    var storeURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("game-library-acceptance-\(id.uuidString).store")
    }

    var keychainService: String {
        "com.leventsuleymanoglulari.game-library.acceptance.\(id.uuidString)"
    }

    static func parse(_ raw: String?) -> AcceptanceSession? {
        guard let raw, let id = UUID(uuidString: raw) else { return nil }
        return AcceptanceSession(id: id)
    }

    static var current: AcceptanceSession? {
        parse(ProcessInfo.processInfo.environment["GAME_LIBRARY_ACCEPTANCE_ID"])
    }
}
