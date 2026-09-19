//
//  ContentView.swift
//  Game library
//
//  Created by Levent Suleymanoglulari on 20/09/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Game.addedDate, order: .reverse) private var games: [Game]

    @State private var searchText: String = ""
    @State private var selectedPlatform: Platform? = nil
    @State private var selectedStatus: GameStatus? = nil

    @State private var showingAddSheet = false
    @State private var editingGame: Game?

    private var filteredGames: [Game] {
        games.filter { game in
            let matchesSearch: Bool
            if searchText.isEmpty {
                matchesSearch = true
            } else {
                let haystack = (game.title + " " + (game.notes ?? "")).lowercased()
                matchesSearch = haystack.contains(searchText.lowercased())
            }

            let matchesPlatform = selectedPlatform == nil || game.platform == selectedPlatform
            let matchesStatus = selectedStatus == nil || game.status == selectedStatus

            return matchesSearch && matchesPlatform && matchesStatus
        }
    }

    var body: some View {
        NavigationSplitView {
            List {
                if filteredGames.isEmpty {
                    ContentUnavailableView("No Games",
                                           systemImage: "gamecontroller",
                                           description: Text("Add games from Steam, Epic Games, and more."))
                } else {
                    ForEach(filteredGames) { game in
                        NavigationLink {
                            GameDetailView(game: game)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(game.title)
                                        .font(.headline)
                                    Spacer()
                                    Text(game.platform.rawValue)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                HStack {
                                    Text(game.status.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(game.addedDate, format: Date.FormatStyle(date: .abbreviated, time: .omitted))
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .contextMenu {
                            Button("Edit") { editingGame = game }
                            Button(role: .destructive) {
                                delete(game)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: delete(offsets:))
                }
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 220, ideal: 260)
#endif
            .navigationTitle("Library")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("Add Game", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Platform", selection: Binding(
                            get: { selectedPlatform ?? Platform?.none ?? nil },
                            set: { newValue in selectedPlatform = newValue }
                        )) {
                            Text("All Platforms").tag(Platform?.none)
                            ForEach(Platform.allCases, id: \.self) { platform in
                                Text(platform.rawValue).tag(Platform?.some(platform))
                            }
                        }

                        Picker("Status", selection: Binding(
                            get: { selectedStatus ?? GameStatus?.none ?? nil },
                            set: { newValue in selectedStatus = newValue }
                        )) {
                            Text("All Statuses").tag(GameStatus?.none)
                            ForEach(GameStatus.allCases, id: \.self) { status in
                                Text(status.rawValue).tag(GameStatus?.some(status))
                            }
                        }

                        Button {
                            selectedPlatform = nil
                            selectedStatus = nil
                        } label: {
                            Label("Clear Filters", systemImage: "line.3.horizontal.decrease.circle")
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .searchable(text: $searchText, placement: .automatic, prompt: Text("Search games"))
            .sheet(isPresented: $showingAddSheet) {
                AddEditGameSheet(
                    title: "Add Game",
                    initialGame: nil,
                    onSave: { title, platform, status, notes in
                        addGame(title: title, platform: platform, status: status, notes: notes)
                    }
                )
#if os(iOS) || os(visionOS)
                .presentationDetents([.medium, .large])
#endif
            }
            .sheet(item: $editingGame) { game in
                AddEditGameSheet(
                    title: "Edit Game",
                    initialGame: game,
                    onSave: { title, platform, status, notes in
                        updateGame(game, title: title, platform: platform, status: status, notes: notes)
                    }
                )
#if os(iOS) || os(visionOS)
                .presentationDetents([.medium, .large])
#endif
            }
        } detail: {
            Text("Select a game")
                .foregroundStyle(.secondary)
        }
    }

    private func addGame(title: String, platform: Platform, status: GameStatus, notes: String?) {
        withAnimation {
            let game = Game(title: title, platform: platform, status: status, notes: notes)
            modelContext.insert(game)
        }
    }

    private func updateGame(_ game: Game, title: String, platform: Platform, status: GameStatus, notes: String?) {
        withAnimation {
            game.title = title
            game.platform = platform
            game.status = status
            game.notes = notes
        }
    }

    private func delete(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredGames[index])
            }
        }
    }

    private func delete(_ game: Game) {
        withAnimation {
            modelContext.delete(game)
        }
    }
}

private struct GameDetailView: View {
    let game: Game

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(game.title)
                        .font(.title2).bold()
                    Spacer()
                    Text(game.platform.rawValue)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    Label(game.status.rawValue, systemImage: "checkmark.circle")
                    Text("Added \(game.addedDate, format: Date.FormatStyle(date: .abbreviated, time: .omitted))")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                if let notes = game.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes").font(.headline)
                        Text(notes)
                    }
                } else {
                    ContentUnavailableView("No Notes", systemImage: "note.text", description: Text("Add notes to keep track of your progress."))
                }
            }
            .padding()
        }
        .navigationTitle(game.title)
    }
}

private struct AddEditGameSheet: View {
    let title: String
    let initialGame: Game?
    let onSave: (String, Platform, GameStatus, String?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var gameTitle: String = ""
    @State private var platform: Platform = .steam
    @State private var status: GameStatus = .backlog
    @State private var notes: String = ""

    init(title: String, initialGame: Game?, onSave: @escaping (String, Platform, GameStatus, String?) -> Void) {
        self.title = title
        self.initialGame = initialGame
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $gameTitle)
#if os(iOS)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
#endif
#if os(macOS)
                        .textCase(nil) // no-op placeholder to keep conditional blocks tidy
#endif

                    Picker("Platform", selection: $platform) {
                        ForEach(Platform.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }

                    Picker("Status", selection: $status) {
                        ForEach(GameStatus.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
#if os(iOS)
                        .disableAutocorrection(false)
#endif
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(gameTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                               platform,
                               status,
                               notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes)
                        dismiss()
                    }
                    .disabled(gameTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let g = initialGame {
                    gameTitle = g.title
                    platform = g.platform
                    status = g.status
                    notes = g.notes ?? ""
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Game.self, inMemory: true)
}
