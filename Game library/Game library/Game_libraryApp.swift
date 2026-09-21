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
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: Game_libraryApp.usesTestStorage)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
