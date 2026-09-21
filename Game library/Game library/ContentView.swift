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
    @State private var alertMessage: String?

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
        .sheet(isPresented: $isShowingAddGame) {
            AddGameSheet(existingRAWGIDs: Set(games.compactMap { game in
                game.source == "rawg" ? game.externalID : nil
            })) { game in save(game) }
        }
        .alert("Oyun eklenemedi", isPresented: Binding(
            get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) { alertMessage = nil }
        } message: { Text(alertMessage ?? "") }
    }

    private func save(_ game: Game) {
        do {
            modelContext.insert(game)
            try modelContext.save()
        } catch {
            modelContext.rollback()
            alertMessage = "Yerel kayıt tamamlanamadı. Lütfen tekrar deneyin."
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
            if game.source == "rawg", let sourceURL = game.sourceURL, let url = URL(string: sourceURL) {
                Link("RAWG'de görüntüle", destination: url).font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

private struct AddGameSheet: View {
    let existingRAWGIDs: Set<Int>
    let onSave: (Game) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var manualTitle = ""
    @State private var apiKey = ""
    @State private var results: [RAWGGame] = []
    @State private var page = 1
    @State private var hasNextPage = false
    @State private var isSearching = false
    @State private var isShowingKeyEditor = false
    @State private var errorMessage: String?
    @State private var duplicateMessage: String?
    private let service = RAWGService()

    private var trimmedSearch: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedManualTitle: String { manualTitle.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section("RAWG kataloğunda ara") {
                    TextField("Oyun adı", text: $searchText)
                        .onSubmit { Task { await search(resetPage: true) } }
                    HStack {
                        Button("Ara") { Task { await search(resetPage: true) } }
                            .disabled(trimmedSearch.isEmpty || isSearching)
                        Button("API Anahtarını Ayarla") { isShowingKeyEditor = true }
                    }
                    if isSearching { ProgressView("RAWG aranıyor…") }
                    if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
                    ForEach(results) { result in RAWGResultRow(result: result) { importGame(result) } }
                    if hasNextPage {
                        Button("Sonraki 20 sonucu yükle") { Task { await search(resetPage: false) } }
                            .disabled(isSearching)
                    }
                }
                Section {
                    TextField("Oyun adı", text: $manualTitle)
                    Button("Elle Ekle") {
                        onSave(Game(title: trimmedManualTitle))
                        dismiss()
                    }
                    .disabled(trimmedManualTitle.isEmpty)
                } header: {
                    Text("Elle ekle")
                } footer: {
                    Text("Elle ekleme çevrimdışı da çalışır. Arama sonuç vermezse aradığınız adı burada kullanabilirsiniz.")
                }
            }
            .navigationTitle("Oyun Ekle")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Kapat") { dismiss() } } }
            .sheet(isPresented: $isShowingKeyEditor) {
                APIKeySheet { key in apiKey = key }
            }
            .alert("Bu oyun zaten eklendi", isPresented: Binding(
                get: { duplicateMessage != nil }, set: { if !$0 { duplicateMessage = nil } }
            )) {
                Button("Tamam", role: .cancel) { duplicateMessage = nil }
            } message: { Text(duplicateMessage ?? "") }
        }
        .frame(minWidth: 560, minHeight: 520)
        .task { await loadKey() }
    }

    @MainActor private func loadKey() async {
        do { apiKey = try KeychainStore.loadRAWGKey() ?? "" }
        catch { errorMessage = "Kaydedilmiş API anahtarı okunamadı. Elle ekleme kullanılabilir." }
    }

    private func search(resetPage: Bool) async {
        let targetPage = resetPage ? 1 : page + 1
        guard !trimmedSearch.isEmpty else { return }
        manualTitle = trimmedSearch
        isSearching = true
        errorMessage = nil
        do {
            let response = try await service.search(query: trimmedSearch, page: targetPage, apiKey: apiKey)
            results = resetPage ? response.results : results + response.results
            page = targetPage
            hasNextPage = response.next != nil
        } catch {
            if resetPage { results = [] }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Ağ bağlantısı kurulamadı. Elle ekleme kullanılabilir."
        }
        isSearching = false
    }

    private func importGame(_ result: RAWGGame) {
        guard !existingRAWGIDs.contains(result.id) else {
            duplicateMessage = "Bu RAWG oyunu zaten kütüphanenizde. Yeni kayıt oluşturulmadı."
            return
        }
        let title = result.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            errorMessage = "RAWG sonucu geçerli bir oyun adı içermiyor. Elle ekleme kullanılabilir."
            return
        }
        onSave(Game(title: title, source: "rawg", externalID: result.id,
                    sourceURL: result.sourceURL?.absoluteString, releaseDate: result.released,
                    platforms: result.platformNames))
        dismiss()
    }
}

private struct RAWGResultRow: View {
    let result: RAWGGame
    let onImport: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.name).font(.headline)
                if let released = result.released { Text("Çıkış: \(released)").font(.caption) }
                if !result.platformNames.isEmpty {
                    Text(result.platformNames.joined(separator: ", ")).font(.caption).foregroundStyle(.secondary)
                }
                if let url = result.sourceURL { Link("RAWG kaynağı", destination: url).font(.caption) }
            }
            Spacer()
            Button("Ekle", action: onImport)
        }
        .padding(.vertical, 4)
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
