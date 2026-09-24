import Foundation

enum RAWGKeyResolver {
    nonisolated static func resolve(keychainKey: String?, buildSecret: String) -> String {
        let stored = keychainKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !stored.isEmpty { return stored }
        let baked = buildSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        if baked == "$(RAWG_API_KEY)" { return "" }
        return baked
    }
}
