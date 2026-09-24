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
        let modelConfiguration: ModelConfiguration
        if Game_libraryApp.usesTestStorage {
            var configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            #if DEBUG
            if let value = ProcessInfo.processInfo.environment["GAME_LIBRARY_TEST_STORE_ID"],
               let identifier = UUID(uuidString: value) {
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("game-library-ui-\(identifier.uuidString).store")
                configuration = ModelConfiguration(schema: schema, url: url)
            }
            #endif
            modelConfiguration = configuration
        } else if let session = AcceptanceSession.current {
            modelConfiguration = ModelConfiguration(schema: schema, url: session.storeURL)
        } else {
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }

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
