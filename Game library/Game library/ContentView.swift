//
//  ContentView.swift
//  Game library
//

import SwiftData
import SwiftUI

private enum LibraryTab: CaseIterable, Hashable {
    case allGames
    case library
    case wishlist
    case toPlay

    var title: String {
        switch self {
        case .allGames: "Tüm Oyunlar"
        case .library: "Kütüphanem"
        case .wishlist: "Wishlist"
        case .toPlay: "Oynanacak"
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

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(LibraryTab.allCases, id: \.self) { tab in
                GameListView(games: games.filter(tab.includes), tab: tab)
                    .tabItem {
                        Label(tab.title, systemImage: iconName(for: tab))
                    }
                    .tag(tab)
            }
        }
        .frame(minWidth: 620, minHeight: 420)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isShowingAddGame = true
                } label: {
                    Label("Oyun Ekle", systemImage: "plus")
                }
                .accessibilityHint("Kütüphaneye yalnızca oyun adıyla yeni bir kayıt ekler.")
            }
        }
        .sheet(isPresented: $isShowingAddGame) {
            AddGameSheet { title in
                addGame(named: title)
            }
        }
    }

    private func iconName(for tab: LibraryTab) -> String {
        switch tab {
        case .allGames: "gamecontroller"
        case .library: "books.vertical"
        case .wishlist: "heart"
        case .toPlay: "play.circle"
        }
    }

    private func addGame(named title: String) {
        withAnimation {
            modelContext.insert(Game(title: title))
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
                    emptyTitle,
                    systemImage: "gamecontroller",
                    description: Text(emptyDescription)
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(games) { game in
                            GameCard(game: game)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(tab.title)
    }

    private var emptyTitle: String {
        tab == .allGames ? "Henüz oyun yok" : "Bu sekmede oyun yok"
    }

    private var emptyDescription: String {
        tab == .allGames
            ? "Başlamak için araç çubuğundan Oyun Ekle'yi seçin."
            : "Oyun durumlarını bir sonraki aşamada düzenleyebilirsiniz."
    }
}

private struct GameCard: View {
    let game: Game

    var body: some View {
        Text(game.title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel(game.title)
    }
}

private struct AddGameSheet: View {
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Oyun adı", text: $title)
                    .accessibilityHint("Eklemek istediğiniz oyunun adını girin.")
            }
            .navigationTitle("Oyun Ekle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ekle") {
                        onSave(trimmedTitle)
                        dismiss()
                    }
                    .disabled(trimmedTitle.isEmpty)
                }
            }
        }
        .frame(minWidth: 360, minHeight: 160)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Game.self, inMemory: true)
}
