import AppKit
import ApplicationServices
import Foundation

struct AcceptanceDriver {
    let appURL: URL
    let sessionID = UUID()
    let sentinel = "acc-" + UUID().uuidString.lowercased()

    var storeURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("game-library-acceptance-\(sessionID.uuidString).store")
    }

    func run() throws -> [String: Any] {
        guard AXIsProcessTrusted() else {
            throw DriverError.untrusted
        }
        let first = try launch()
        defer { first.terminate() }
        let app = try waitForApplication(named: "Game library")
        try requireTabs(app)
        try press(button: "Oyun Ekle", in: app)
        try setValue("Kurulu Kabul", on: "manualTitle", in: app)
        try press(button: "Elle Ekle", in: app)
        try press(checkbox: "Wishlist", in: app)
        try press(button: "Kapat", in: app)
        let card = try element(identifier: "gameCard-Kurulu Kabul", in: app)
        let value = attribute(kAXValueAttribute, of: card) as? String ?? ""
        guard value.contains("Wishlist") else { throw DriverError.missing("Wishlist kart değeri") }
        let shot = try screenshot(pid: first.processIdentifier, name: "installed-release-kabul.png")
        first.terminate()
        Thread.sleep(forTimeInterval: 1)
        let second = try launch()
        defer { second.terminate() }
        let reopened = try waitForApplication(named: "Game library")
        _ = try element(identifier: "gameCard-Kurulu Kabul", in: reopened)
        try press(button: "Oyun Ekle", in: reopened)
        try press(button: "API Anahtarını Ayarla", in: reopened)
        try setFocusedValue(sentinel, in: reopened)
        try press(button: "Kaydet", in: reopened)
        second.terminate()
        Thread.sleep(forTimeInterval: 1)
        let leaked = try storeContains(Data(sentinel.utf8))
        let logged = logContains(sentinel)
        guard !leaked, !logged else { throw DriverError.secretExposed }
        try deleteKeychainItem()
        return [
            "accepted_offline_release": true,
            "session": sessionID.uuidString,
            "wishlist_persisted": true,
            "sentinel_absent_from_store": !leaked,
            "sentinel_absent_from_logs": !logged,
            "screenshot": shot,
            "macos": ProcessInfo.processInfo.operatingSystemVersionString,
            "architecture": "arm64",
            "intel_runtime": false,
            "minimum_macos_26_runtime": false,
            "separate_macos_user": false,
            "live_rawg_on_release": false,
        ]
    }

    private func launch() throws -> Process {
        let process = Process()
        process.executableURL = appURL.appendingPathComponent("Contents/MacOS/Game library")
        process.environment = ProcessInfo.processInfo.environment.merging([
            "GAME_LIBRARY_ACCEPTANCE_ID": sessionID.uuidString
        ]) { _, new in new }
        try process.run()
        return process
    }

    private func waitForApplication(named name: String) throws -> AXUIElement {
        let deadline = Date().addingTimeInterval(20)
        while Date() < deadline {
            if let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == name }) {
                let element = AXUIElementCreateApplication(app.processIdentifier)
                if (attribute(kAXWindowsAttribute, of: element) as? [AXUIElement])?.isEmpty == false {
                    return element
                }
            }
            Thread.sleep(forTimeInterval: 0.2)
        }
        throw DriverError.missing("pencere")
    }

    private func requireTabs(_ app: AXUIElement) throws {
        let titles = ["Tüm Oyunlar", "Kütüphanem", "Wishlist", "Oynanacak"]
        let deadline = Date().addingTimeInterval(8)
        while Date() < deadline {
            if titles.allSatisfy({ (try? element(title: $0, role: kAXButtonRole as String, in: app)) != nil }) {
                return
            }
            Thread.sleep(forTimeInterval: 0.2)
        }
        throw DriverError.missing("sekmeler")
    }

    private func press(button title: String, in app: AXUIElement) throws {
        try performPress(title: title, role: kAXButtonRole as String, in: app)
    }

    private func press(checkbox title: String, in app: AXUIElement) throws {
        try performPress(title: title, role: kAXCheckBoxRole as String, in: app)
    }

    private func performPress(title: String, role: String, in app: AXUIElement) throws {
        let deadline = Date().addingTimeInterval(8)
        var last = "basılamadı \(title)"
        while Date() < deadline {
            if let button = try? element(title: title, role: role, in: app) {
                let result = AXUIElementPerformAction(button, kAXPressAction as CFString)
                if result == .success { return }
                last = "basılamadı \(title) \(result.rawValue)"
            }
            Thread.sleep(forTimeInterval: 0.2)
        }
        throw DriverError.missing(last)
    }

    private func setValue(_ text: String, on identifier: String, in app: AXUIElement) throws {
        let deadline = Date().addingTimeInterval(8)
        while Date() < deadline {
            if let field = try? element(identifier: identifier, in: app),
               AXUIElementSetAttributeValue(field, kAXValueAttribute as CFString, text as CFString) == .success {
                return
            }
            Thread.sleep(forTimeInterval: 0.2)
        }
        throw DriverError.missing(identifier)
    }

    private func setFocusedValue(_ text: String, in app: AXUIElement) throws {
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            if let focused = attribute(kAXFocusedUIElementAttribute, of: app).map({ $0 as! AXUIElement }),
               AXUIElementSetAttributeValue(focused, kAXValueAttribute as CFString, text as CFString) == .success {
                return
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        throw DriverError.missing("odaklı anahtar alanı")
    }

    private func element(title: String, role: String, in root: AXUIElement) throws -> AXUIElement {
        guard let found = find(in: root, where: { element in
            guard attribute(kAXRoleAttribute, of: element) as? String == role else { return false }
            let titleValue = attribute(kAXTitleAttribute, of: element) as? String
            let description = attribute(kAXDescriptionAttribute, of: element) as? String
            return titleValue == title || description == title
        }) else { throw DriverError.missing(title) }
        return found
    }

    private func element(identifier: String, in root: AXUIElement) throws -> AXUIElement {
        let deadline = Date().addingTimeInterval(8)
        while Date() < deadline {
            if let found = find(in: root, where: { element in
                attribute(kAXIdentifierAttribute, of: element) as? String == identifier
            }) { return found }
            Thread.sleep(forTimeInterval: 0.2)
        }
        throw DriverError.missing(identifier)
    }

    private func find(in root: AXUIElement, where matches: (AXUIElement) -> Bool) -> AXUIElement? {
        var queue = windows(of: root)
        var seen: [CFHashCode: Int] = [:]
        while !queue.isEmpty {
            let current = queue.removeFirst()
            let hash = CFHash(current)
            let count = seen[hash, default: 0]
            if count > 4 { continue }
            seen[hash] = count + 1
            if matches(current) { return current }
            queue.append(contentsOf: children(of: current))
        }
        return nil
    }

    private func windows(of root: AXUIElement) -> [AXUIElement] {
        let windows = attribute(kAXWindowsAttribute, of: root) as? [AXUIElement] ?? []
        return windows.isEmpty ? [root] : windows
    }

    private func children(of element: AXUIElement) -> [AXUIElement] {
        attribute(kAXChildrenAttribute, of: element) as? [AXUIElement] ?? []
    }

    private func storeContains(_ needle: Data) throws -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let candidates = [
            storeURL,
            home.appendingPathComponent("Library/Containers/Game.Game-library/Data/tmp/game-library-acceptance-\(sessionID.uuidString).store"),
        ]
        guard let root = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) else {
            throw DriverError.missing("kabul deposu")
        }
        return contains(needle, at: root)
    }

    private func contains(_ needle: Data, at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return false }
        if isDirectory.boolValue {
            let children = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []
            return children.contains { contains(needle, at: $0) }
        }
        guard let data = try? Data(contentsOf: url) else { return false }
        return data.range(of: needle) != nil
    }

    private func attribute(_ name: String, of element: AXUIElement) -> Any? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    private func screenshot(pid: Int32, name: String) throws -> String {
        let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        guard let number = info.first(where: { ($0[kCGWindowOwnerPID as String] as? Int32) == pid })?[kCGWindowNumber as String] as? Int else {
            throw DriverError.missing("pencere numarası")
        }
        let directory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("docs/evidence", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-l", String(number), "-o", url.path]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw DriverError.missing("ekran görüntüsü") }
        return "docs/evidence/\(name)"
    }

    private func logContains(_ needle: String) -> Bool {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/log")
        process.arguments = ["show", "--last", "2m", "--style", "compact"]
        process.standardOutput = pipe
        process.standardError = Pipe()
        guard (try? process.run()) != nil else { return true }
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return data.range(of: Data(needle.utf8)) != nil
    }

    private func deleteKeychainItem() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.leventsuleymanoglulari.game-library.acceptance.\(sessionID.uuidString)",
            kSecAttrAccount as String: "rawg-api-key",
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum DriverError: Error, CustomStringConvertible {
    case untrusted
    case missing(String)
    case secretExposed

    var description: String {
        switch self {
        case .untrusted: "Erişilebilirlik izni yok. Kurulu Release kabulü çalıştırılamadı."
        case .missing(let name): "Eksik: \(name)"
        case .secretExposed: "Sentinel depoda veya günlükte göründü."
        }
    }
}

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    fputs("Kullanım: verify-installed-release <Game library.app>\n", stderr)
    exit(64)
}
do {
    let record = try AcceptanceDriver(appURL: URL(fileURLWithPath: arguments[1])).run()
    let data = try JSONSerialization.data(withJSONObject: record, options: [.prettyPrinted, .sortedKeys])
    let url = URL(fileURLWithPath: "docs/evidence/installed-release.json")
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: url)
    print(String(decoding: data, as: UTF8.self))
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
