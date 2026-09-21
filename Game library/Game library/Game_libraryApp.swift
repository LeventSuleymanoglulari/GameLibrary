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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Game.self,
        ])
        #if DEBUG
        let inMemory = ProcessInfo.processInfo.arguments.contains("--ui-testing")
        #else
        let inMemory = false
        #endif
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)

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
