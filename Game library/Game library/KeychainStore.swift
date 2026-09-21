import Foundation
import Security

enum KeychainStore {
    private static let service = "com.leventsuleymanoglulari.game-library"
    private static let account = "rawg-api-key"

    #if DEBUG
    private static var testKey: String?
    #endif

    static func loadRAWGKey() throws -> String? {
        #if DEBUG
        if Game_libraryApp.usesTestStorage { return testKey }
        #endif
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedStatus(status)
        }
        return key
    }

    static func saveRAWGKey(_ key: String) throws {
        #if DEBUG
        if Game_libraryApp.usesTestStorage { testKey = key; return }
        #endif
        let data = Data(key.utf8)
        let attributes: [String: Any] = [kSecValueData as String: data]
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var newItem = query
            newItem[kSecValueData as String] = data
            let addStatus = SecItemAdd(newItem as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw KeychainError.unexpectedStatus(addStatus) }
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    enum KeychainError: LocalizedError {
        case unexpectedStatus(OSStatus)

        var errorDescription: String? {
            "API anahtarı güvenli saklamaya kaydedilemedi."
        }
    }
}
