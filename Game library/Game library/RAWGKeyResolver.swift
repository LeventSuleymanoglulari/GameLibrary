import Foundation

enum RAWGKeyResolver {
    nonisolated static func resolve(keychainKey: String?, buildSecret: String) -> String {
        let stored = keychainKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !stored.isEmpty { return stored }
        return buildSecret.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
