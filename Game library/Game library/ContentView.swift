//
//  ContentView.swift
//  Game library
//

import SwiftData
import SwiftUI

private enum LibraryTab: CaseIterable, Hashable {
    case allGames, library, wishlist, toPlay

    var title: String {
        switch self {
        case .allGames: "Tüm Oyunlar"
        case .library: "Kütüphanem"
        case .wishlist: "Wishlist"
        case .toPlay: "Oynanacak"
        }
    }

    var iconName: String {
        switch self {
        case .allGames: "gamecontroller"
        case .library: "books.vertical"
        case .wishlist: "heart"
        case .toPlay: "play.circle"
        }
    }

    func includes(_ game: Game) -> Bool {
        switch self {
        case .allGames: true
        case .library: game.isInLibrary
        case .wishlist: game.isWishlisted
        case .toPlay: game.isToPlay
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Game.addedDate, order: .reverse) private var games: [Game]
    @State private var selectedTab: LibraryTab = .allGames
    @State private var isShowingAddGame = false
    @State private var selectedGame: Game?
    @State private var pendingGame: Game?

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(LibraryTab.allCases, id: \.self) { tab in
                GameListView(games: games.filter(tab.includes), tab: tab)
                    .tabItem { Label(tab.title, systemImage: tab.iconName) }
                    .tag(tab)
            }
        }
        .frame(minWidth: 620, minHeight: 420)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { isShowingAddGame = true } label: {
                    Label("Oyun Ekle", systemImage: "plus")
                }
                .accessibilityHint("RAWG kataloğunda arama veya elle oyun ekleme akışını açar.")
            }
        }
        .sheet(isPresented: $isShowingAddGame, onDismiss: {
            selectedGame = pendingGame
            pendingGame = nil
        }) {
            AddGameSheet { game in
                selectedTab = .allGames
                pendingGame = game
            }
        }
        .sheet(item: $selectedGame) { game in
            VStack(alignment: .leading, spacing: 16) {
                GameCard(game: game)
                if let date = game.releaseDate { Text("Çıkış: \(date)") }
                if !game.platforms.isEmpty { Text(game.platforms.joined(separator: ", ")) }
                Button("Kapat") { selectedGame = nil }
            }
            .padding().frame(minWidth: 400)
        }
    }
}

private struct GameListView: View {
    let games: [Game]
    let tab: LibraryTab

    var body: some View {
        Group {
            if games.isEmpty {
                ContentUnavailableView(
                    tab == .allGames ? "Henüz oyun yok" : "Bu sekmede oyun yok",
                    systemImage: "gamecontroller",
                    description: Text(tab == .allGames
                        ? "Başlamak için araç çubuğundan Oyun Ekle'yi seçin."
                        : "Oyun durumlarını bir sonraki aşamada düzenleyebilirsiniz.")
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(games) { game in GameCard(game: game) }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(tab.title)
    }
}

private struct GameCard: View {
    let game: Game

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(game.title).font(.headline)
            if game.source == "rawg" {
                Link("RAWG'de görüntüle", destination: RAWGService.safeSourceURL(game.sourceURL)).font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .contain)
    }
}

private struct AddGameSheet: View {
    let onOpen: (Game) -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var search = CatalogSearchSession()
    @State private var searchText = ""
    @State private var manualTitle = ""
    @State private var apiKey = ""
    @State private var selectedResult: RAWGGame?
    @State private var manualEntryOnly = false
    @State private var isShowingKeyEditor = false
    @State private var errorMessage: String?
    @State private var pendingDraft: GameDraft?
    @State private var nameMatches: [Game] = []
    @State private var requestTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            Form {
                if !manualEntryOnly {
                    Section("RAWG kataloğunda ara") {
                        TextField("Aranacak oyun adı", text: $searchText)
                            .accessibilityIdentifier("searchTitle")
                            .onSubmit { startSearch() }
                        HStack {
                            Button("Ara") { startSearch() }
                                .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || search.isSearching)
                            Button("API Anahtarını Ayarla") { isShowingKeyEditor = true }
                            Link("RAWG kaynağı", destination: RAWGService.attributionURL)
                        }
                        if apiKey.isEmpty {
                            Text("Katalog araması için RAWG API anahtarınızı ayarlayın. Elle ekleme her zaman kullanılabilir.")
                        }
                        if search.isSearching { ProgressView("RAWG aranıyor…") }
                        if let message = search.errorMessage {
                            Text(message).foregroundStyle(.red)
                            Button("Tekrar dene") { requestTask = Task { await search.retry(apiKey: apiKey) } }
                                .disabled(search.isSearching)
                        }
                        if search.hasSearched, search.results.isEmpty, !search.isSearching, search.errorMessage == nil {
                            Text("Sonuç bulunamadı. Aradığınız adla elle ekleyebilirsiniz.")
                        }
                        if !search.results.isEmpty {
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 12) {
                                    ForEach(search.results) { result in
                                        HStack(alignment: .top) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(result.name).font(.headline)
                                                if let released = result.released { Text("Çıkış: \(released)").font(.caption) }
                                                if !result.platformNames.isEmpty {
                                                    Text(result.platformNames.joined(separator: ", ")).font(.caption)
                                                }
                                                Link("RAWG kaynağı", destination: result.sourceURL).font(.caption)
                                            }
                                            Spacer()
                                            Button(selectedResult?.id == result.id ? "Seçildi" : "Seç") { selectedResult = result }
                                        }
                                    }
                                }
                            }
                            .frame(height: 180)
                        }
                        if let selectedResult {
                            Button("Seçilen Oyunu Ekle") {
                                do { try add(GameDraft.rawg(selectedResult)) }
                                catch { errorMessage = "Yerel kayıt tamamlanamadı. Seçiminiz korunuyor; tekrar deneyebilirsiniz." }
                            }
                        }
                        if search.hasNextPage {
                            Button("Sonraki 20 sonucu yükle") { requestTask = Task { await search.loadNext(apiKey: apiKey) } }
                                .disabled(search.isSearching)
                        }
                    }
                }
                Section("Elle ekle") {
                    TextField("Oyun adı", text: $manualTitle).accessibilityIdentifier("manualTitle")
                    Button("Elle Ekle") {
                        do { try add(GameDraft.manual(manualTitle)) }
                        catch { errorMessage = "Yerel kayıt tamamlanamadı. Girdiğiniz ad korunuyor; tekrar deneyebilirsiniz." }
                    }
                    .disabled(manualTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Text("Elle ekleme çevrimdışı da çalışır.").font(.footnote)
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
                if let pendingDraft {
                    Section("Aynı adlı oyun zaten var") {
                        Text("Mevcut kaydı açın veya bunun ayrı bir oyun olduğunu onaylayın.")
                        ForEach(nameMatches) { game in
                            Button("Mevcut kaydı aç: \(game.title)") { onOpen(game); dismiss() }
                        }
                        Button("Ayrı Oyun Olarak Ekle") {
                            do { try add(pendingDraft, confirmed: true) }
                            catch { errorMessage = "Yerel kayıt tamamlanamadı. Lütfen tekrar deneyin." }
                        }
                        Button("Vazgeç") { self.pendingDraft = nil; nameMatches = [] }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Oyun Ekle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Kapat") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button(manualEntryOnly ? "Katalogda ara" : "Elle ekle") { manualEntryOnly.toggle() }
                }
            }
            .sheet(isPresented: $isShowingKeyEditor) { APIKeySheet { apiKey = $0 } }
        }
        .frame(minWidth: 560, minHeight: 520)
        .task {
            do { apiKey = try KeychainStore.loadRAWGKey() ?? "" }
            catch { errorMessage = "Kaydedilmiş API anahtarı okunamadı. Elle ekleme kullanılabilir." }
        }
        .onDisappear { requestTask?.cancel() }
        .onChange(of: manualTitle) { pendingDraft = nil; nameMatches = [] }
        .onChange(of: selectedResult) { pendingDraft = nil; nameMatches = [] }
        .onChange(of: searchText) { pendingDraft = nil; nameMatches = [] }
    }

    private func startSearch() {
        guard !search.isSearching else { return }
        manualTitle = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        selectedResult = nil
        let query = searchText
        let key = apiKey
        requestTask = Task { await search.search(query, apiKey: key) }
    }

    private func add(_ draft: GameDraft, confirmed: Bool = false) throws {
        errorMessage = nil
        #if DEBUG
        let failingSave: (() throws -> Void)? = ProcessInfo.processInfo.arguments.contains("--ui-testing-save-failure")
            ? { throw CocoaError(.fileWriteNoPermission) } : nil
        #else
        let failingSave: (() throws -> Void)? = nil
        #endif
        switch try Game.add(draft, to: modelContext, allowSameName: confirmed, save: failingSave) {
        case .added(let game), .existing(let game):
            onOpen(game)
            dismiss()
        case .sameName(let games):
            pendingDraft = draft
            nameMatches = games
        }
    }
}

private struct APIKeySheet: View {
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var key = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                SecureField("RAWG API anahtarı", text: $key)
                Text("Anahtar yalnızca bu Mac'in Keychain'inde saklanır; oyun kayıtlarına veya günlük kaydına yazılmaz.")
                    .font(.footnote).foregroundStyle(.secondary)
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .navigationTitle("RAWG API Anahtarı")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Vazgeç") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                        .disabled(key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 440, minHeight: 190)
    }

    private func save() {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try KeychainStore.saveRAWGKey(trimmedKey)
            onSave(trimmedKey)
            dismiss()
        } catch { errorMessage = "API anahtarı güvenli saklamaya kaydedilemedi." }
    }
}

#Preview { ContentView().modelContainer(for: Game.self, inMemory: true) }
