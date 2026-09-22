#!/usr/bin/env python3
"""Gerçek Keychain kodunu ayrı test hizmetiyle iki süreçte doğrular; gerçek anahtara dokunmaz."""

from pathlib import Path
import subprocess
import tempfile
import uuid


ROOT = Path(__file__).resolve().parents[2]
PRODUCTION_SERVICE = "com.leventsuleymanoglulari.game-library"


def main():
    service = "game-library-verification-" + str(uuid.uuid4())
    source = (ROOT / "Game library/Game library/KeychainStore.swift").read_text()
    assert source.count(PRODUCTION_SERVICE) == 1
    with tempfile.TemporaryDirectory(prefix="game-library-keychain-") as directory:
        work = Path(directory)
        # Yalnızca hizmet adı değiştirilir; Security çağrıları üretim kodudur.
        (work / "KeychainStore.swift").write_text(source.replace(PRODUCTION_SERVICE, service))
        (work / "Check.swift").write_text(r'''
import Foundation
import Security

@main struct Check {
    @MainActor static func main() throws {
        switch CommandLine.arguments[1] {
        case "write":
            let initial = try KeychainStore.loadRAWGKey()
            precondition(initial == nil)
            try KeychainStore.saveRAWGKey("synthetic-not-a-real-api-key")
            try KeychainStore.saveRAWGKey("synthetic-updated-key")
        case "read":
            let key = try KeychainStore.loadRAWGKey()
            precondition(key == "synthetic-updated-key")
            print("PASS: Sentetik anahtar ayrı süreçte Keychain'den okundu; ekleme ve güncelleme doğru.")
        default:
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: CommandLine.arguments[2],
                kSecAttrAccount as String: "rawg-api-key"
            ]
            let status = SecItemDelete(query as CFDictionary)
            precondition(status == errSecSuccess || status == errSecItemNotFound)
        }
    }
}
''')
        executable = work / "keychain-check"
        subprocess.run([
            "xcrun", "swiftc", "-swift-version", "6", "-default-isolation", "MainActor",
            str(work / "KeychainStore.swift"), str(work / "Check.swift"), "-o", str(executable)
        ], check=True)
        try:
            subprocess.run([str(executable), "write"], check=True, timeout=30)
            subprocess.run([str(executable), "read"], check=True, timeout=30)
        finally:
            subprocess.run([str(executable), "delete", service], check=True, timeout=30)


if __name__ == "__main__":
    main()
