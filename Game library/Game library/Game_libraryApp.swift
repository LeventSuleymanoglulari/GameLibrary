//
//  Game_libraryApp.swift
//  Game library
//
//  Created by Levent Suleymanoglulari on 20/09/2026.
//

import SwiftUI
import SwiftData

@main
struct Game_libraryApp: App {
    @State private var catalogImporter = CatalogImporter()
    static var usesTestStorage: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--ui-testing")
            || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        #else
        false
        #endif
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Game.self,
            CatalogImportProgress.self,
        ])
        var modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: Game_libraryApp.usesTestStorage)
        #if DEBUG
        // Yalnızca UUID tabanlı geçici test deposu; kullanıcı deposuna yol kabul edilmez.
        if Game_libraryApp.usesTestStorage,
           let value = ProcessInfo.processInfo.environment["GAME_LIBRARY_TEST_STORE_ID"],
           let identifier = UUID(uuidString: value) {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("game-library-ui-\(identifier.uuidString).store")
            modelConfiguration = ModelConfiguration(schema: schema, url: url)
        }
        #endif

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(catalogImporter)
        }
        .modelContainer(sharedModelContainer)
    }
}
