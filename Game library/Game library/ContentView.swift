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
                GameListView(games: games.filter(tab.includes), tab: tab) { game in
                    selectedGame = game
                }
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
            GameDetailSheet(game: game)
        }
    }
}

private struct GameListView: View {
    let games: [Game]
    let tab: LibraryTab
    let onOpen: (Game) -> Void

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
                        ForEach(games) { game in
                            Button { onOpen(game) } label: { GameCard(game: game) }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("gameCard-\(game.title)")
                                .accessibilityHint("Oyunun durumlarını ve puanını düzenlemek için açar.")
                        }
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
            if !statusLabels.isEmpty || game.rating != nil {
                HStack(spacing: 6) {
                    ForEach(statusLabels, id: \.self) { label in
                        Text(label)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(.tint.opacity(0.14), in: Capsule())
                    }
                    if let rating = game.rating {
                        Text("Puan: \(rating)/10")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(.orange.opacity(0.16), in: Capsule())
                    }
                }
            }
            if game.source == "rawg" {
                Text("RAWG kataloğundan eklendi").font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(game.title)
        .accessibilityValue((statusLabels + (game.rating.map { ["Puan: \($0)/10"] } ?? [])).joined(separator: ", "))
    }

    private var statusLabels: [String] {
        [
            game.isInLibrary ? "Kütüphane" : nil,
            game.isWishlisted ? "Wishlist" : nil,
            game.isToPlay ? "Oynanacak" : nil,
            game.isPlayed ? "Oynandı" : nil,
            game.isCompleted ? "Bitti" : nil
        ].compactMap { $0 }
    }
}

private struct GameDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var game: Game
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    statusToggle("Kütüphanem", value: $game.isInLibrary)
                    statusToggle("Wishlist", value: $game.isWishlisted)
                    statusToggle("Oynanacak", value: $game.isToPlay)
                    statusToggle("Oynandı", value: $game.isPlayed)
                    statusToggle("Bitti", value: $game.isCompleted)
                } header: {
                    Text("Durumlar")
                } footer: {
                    Text("Durumlar birbirinden bağımsızdır; birini değiştirmek diğerini değiştirmez.")
                }
                Section {
                    Menu {
                        Button("Puanı kaldır") { updateRating(nil) }
                        Divider()
                        ForEach(1...10, id: \.self) { rating in
                            Button("\(rating)/10") { updateRating(rating) }
                        }
                    } label: {
                        LabeledContent("Puan", value: game.rating.map { "\($0)/10" } ?? "Verilmedi")
                    }
                    .accessibilityLabel("Kişisel puan")
                    .accessibilityValue(game.rating.map { "\($0)/10" } ?? "Verilmedi")
                } header: {
                    Text("Kişisel puan")
                }
                if let releaseDate = game.releaseDate {
                    Section {
                        Text("Çıkış: \(releaseDate)")
                    } header: {
                        Text("Katalog bilgisi")
                    }
                }
                if !game.platforms.isEmpty { Text(game.platforms.joined(separator: ", ")) }
                if game.source == "rawg" { Link("RAWG kaynağında görüntüle", destination: RAWGService.safeSourceURL(game.sourceURL)) }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .navigationTitle(game.title)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Bitti") { dismiss() } } }
        }
        .frame(minWidth: 440, minHeight: 400)
    }

    private func statusToggle(_ title: String, value: Binding<Bool>) -> some View {
        Toggle(title, isOn: Binding(
            get: { value.wrappedValue },
            set: { newValue in
                let oldValue = value.wrappedValue
                value.wrappedValue = newValue
                save { value.wrappedValue = oldValue }
            }
        ))
    }

    private func updateRating(_ rating: Int?) {
        guard rating == nil || (1...10).contains(rating!) else { return }
        let oldRating = game.rating
        game.rating = rating
        save { game.rating = oldRating }
    }

    private func save(revert: () -> Void) {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            revert()
            errorMessage = "Değişiklik kaydedilemedi. Lütfen tekrar deneyin."
        }
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
