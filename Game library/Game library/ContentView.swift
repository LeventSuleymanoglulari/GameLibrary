//
//  ContentView.swift
//  Game library
//

import SwiftData
import SwiftUI

enum LibraryTab: CaseIterable, Hashable {
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

    var shortcut: KeyEquivalent {
        switch self {
        case .allGames: "1"
        case .library: "2"
        case .wishlist: "3"
        case .toPlay: "4"
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

private enum LibraryPane: Equatable {
    case browsing
    case inspecting
    case composing
}

private struct ShelfInk {
    let scheme: ColorScheme

    var canvas: Color {
        scheme == .dark
            ? Color(red: 0.11, green: 0.10, blue: 0.09)
            : Color(red: 0.94, green: 0.91, blue: 0.86)
    }

    var rail: Color {
        scheme == .dark
            ? Color(red: 0.15, green: 0.13, blue: 0.11)
            : Color(red: 0.89, green: 0.84, blue: 0.76)
    }

    var spine: Color {
        scheme == .dark
            ? Color(red: 0.20, green: 0.17, blue: 0.15)
            : Color(red: 0.98, green: 0.96, blue: 0.93)
    }

    var pane: Color {
        scheme == .dark
            ? Color(red: 0.16, green: 0.14, blue: 0.12)
            : Color(red: 0.97, green: 0.94, blue: 0.89)
    }

    var ink: Color {
        scheme == .dark
            ? Color(red: 0.96, green: 0.93, blue: 0.88)
            : Color(red: 0.18, green: 0.14, blue: 0.11)
    }

    var secondary: Color {
        scheme == .dark
            ? Color(red: 0.78, green: 0.72, blue: 0.64)
            : Color(red: 0.38, green: 0.32, blue: 0.26)
    }

    var lamp: Color { Color(red: 0.86, green: 0.55, blue: 0.22) }

    var hairline: Color { ink.opacity(0.14) }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Game.addedDate, order: .reverse) private var games: [Game]
    @State private var selectedTab: LibraryTab = .allGames
    @State private var pane: LibraryPane = .browsing
    @State private var selectedGame: Game?

    private var ink: ShelfInk { ShelfInk(scheme: colorScheme) }

    private var motion: Animation {
        reduceMotion
            ? .easeOut(duration: 0.12)
            : .timingCurve(0.16, 1, 0.3, 1, duration: 0.28)
    }

    private var visibleGames: [Game] {
        games.filter(selectedTab.includes)
    }

    var body: some View {
        HStack(spacing: 0) {
            filterRail
            Rectangle().fill(ink.hairline).frame(width: 1)
            shelf
            Rectangle().fill(ink.hairline).frame(width: 1)
            trailingPane
                .frame(width: 400)
        }
        .foregroundStyle(ink.ink)
        .background(ink.canvas)
        .tint(ink.lamp)
        .frame(minWidth: 980, minHeight: 640)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
            Button {
                withAnimation(motion) {
                    if pane == .composing {
                        closeComposer()
                    } else {
                        pane = .composing
                    }
                }
            } label: {
                    Label("Oyun Ekle", systemImage: "plus")
                }
                .accessibilityHint("RAWG kataloğunda arama veya elle oyun ekleme akışını açar.")
            }
        }
    }

    private var filterRail: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Oyun Kütüphanesi")
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 8)
            VStack(spacing: 4) {
                ForEach(LibraryTab.allCases, id: \.self) { tab in
                    filterButton(tab)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(width: 220, alignment: .topLeading)
        .background(ink.rail)
    }

    private func filterButton(_ tab: LibraryTab) -> some View {
        let count = games.filter(tab.includes).count
        let selected = selectedTab == tab
        return Button {
            withAnimation(motion) { selectedTab = tab }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: tab.iconName)
                    .frame(width: 18)
                Text(tab.title)
                    .font(.body.weight(selected ? .semibold : .regular))
                Spacer(minLength: 0)
                Text("\(count)")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(ink.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(selected ? ink.lamp.opacity(0.28) : ink.rail)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(tab.shortcut, modifiers: .command)
        .accessibilityIdentifier(tab.title)
        .accessibilityLabel(tab.title)
        .accessibilityValue("\(count)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var shelf: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(selectedTab.title)
                    .font(.title.weight(.semibold))
                Spacer()
                Text(visibleGames.isEmpty ? "0 oyun" : "\(visibleGames.count) oyun")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(ink.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)

            if visibleGames.isEmpty {
                ContentUnavailableView(
                    selectedTab == .allGames ? "Henüz oyun yok" : "Bu sekmede oyun yok",
                    systemImage: "gamecontroller",
                    description: Text(selectedTab == .allGames
                        ? "Başlamak için araç çubuğundan Oyun Ekle'yi seçin."
                        : GamePresentation.emptyFilteredTabDescription)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(visibleGames) { game in
                            shelfRow(game)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func shelfRow(_ game: Game) -> some View {
        let selected = selectedGame?.persistentModelID == game.persistentModelID && pane == .inspecting
        return VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(motion) {
                    selectedGame = game
                    pane = .inspecting
                }
            } label: {
                GameCard(game: game, ink: ink, emphasized: selected)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("gameCard-\(game.title)")
            .accessibilityValue(GamePresentation.accessibilityValue(for: game))
            .accessibilityHint("Oyunun durumlarını ve puanını düzenlemek için açar.")
            if game.source == "rawg" {
                Link("RAWG kaynağında görüntüle", destination: RAWGService.safeSourceURL(game.sourceURL))
                    .font(.caption)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(selected ? ink.spine : Color.clear)
        )
        .overlay(alignment: .bottom) {
            if !selected {
                Rectangle().fill(ink.hairline).frame(height: 1).padding(.horizontal, 14)
            }
        }
        .shadow(color: .black.opacity(selected ? 0.14 : 0), radius: 12, x: 0, y: 4)
        .animation(motion, value: GamePresentation.accessibilityValue(for: game))
    }

    private var trailingPane: some View {
        ZStack {
            ink.pane
            Group {
                if pane == .composing {
                    AddGameSheet(
                        onOpen: { game in
                            withAnimation(motion) {
                                selectedTab = .allGames
                                selectedGame = game
                                pane = .inspecting
                            }
                        },
                        onClose: closeComposer,
                        onBulkStart: { selectedTab = .allGames }
                    )
                } else if pane == .inspecting, let selectedGame {
                    GameDetailSheet(game: selectedGame, onClose: closeDetail)
                        .id(selectedGame.persistentModelID)
                } else {
                    emptyPane
                }
            }
            .id(pane)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .offset(x: reduceMotion ? 0 : 14)),
                removal: .opacity
            ))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .clipped()
        .shadow(color: .black.opacity(0.12), radius: 16, x: -6, y: 0)
    }

    private var emptyPane: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bir oyun seçin")
                .font(.title2.weight(.semibold))
            Text("Raftan bir oyun seçin. Durum ve puan bu panele gelir. Eklemek için Oyun Ekle.")
                .font(.body)
                .foregroundStyle(ink.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func closeComposer() {
        withAnimation(motion) {
            pane = selectedGame == nil ? .browsing : .inspecting
        }
    }

    private func closeDetail() {
        withAnimation(motion) {
            selectedGame = nil
            pane = .browsing
        }
    }
}

private struct CatalogCover: View {
    let urlString: String?
    let width: CGFloat
    let ink: ShelfInk

    private var url: URL? {
        CatalogArtwork.parse(urlString)?.url
    }

    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    ink.spine
                default:
                    ink.spine.opacity(0.45)
                }
            }
            .frame(width: width, height: width * 1.35)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityHidden(true)
        }
    }
}

private struct GameCard: View {
    let game: Game
    let ink: ShelfInk
    var emphasized: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CatalogCover(urlString: game.artworkURL, width: 44, ink: ink)
            VStack(alignment: .leading, spacing: 8) {
                Text(game.title)
                    .font(.headline)
                    .foregroundStyle(emphasized ? ink.lamp : ink.ink)
                    .multilineTextAlignment(.leading)
                let labels = GamePresentation.statusLabels(for: game)
                if !labels.isEmpty || game.rating != nil {
                HStack(spacing: 6) {
                    ForEach(labels, id: \.self) { label in
                        Text(label)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .foregroundStyle(ink.ink)
                            .background(ink.lamp.opacity(0.18), in: Capsule())
                    }
                    if let chip = GamePresentation.ratingChip(game.rating) {
                        Text(chip)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .foregroundStyle(ink.ink)
                            .background(ink.lamp.opacity(0.32), in: Capsule())
                    }
                }
            }
            if game.source == "rawg" {
                Text("RAWG kataloğundan eklendi")
                    .font(.subheadline)
                    .foregroundStyle(ink.secondary)
            }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(game.title)
        .accessibilityValue(GamePresentation.accessibilityValue(for: game))
    }
}

private struct GameDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var game: Game
    let onClose: () -> Void
    @State private var titleDraft: String
    @State private var errorMessage: String?
    @FocusState private var focus: LibraryFocusTarget?

    private var ink: ShelfInk { ShelfInk(scheme: colorScheme) }

    init(game: Game, onClose: @escaping () -> Void) {
        self.game = game
        self.onClose = onClose
        _titleDraft = State(initialValue: game.title)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                CatalogCover(urlString: game.artworkURL, width: 168, ink: ink)
                HStack(alignment: .firstTextBaseline) {
                    Text(game.title)
                        .font(.title2.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Button(GamePresentation.detailDismissTitle, action: onClose)
                        .accessibilityIdentifier(GamePresentation.detailDismissIdentifier)
                        .focused($focus, equals: .dismissDetail)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Ad")
                        .font(.headline)
                    TextField("Oyun adı", text: $titleDraft)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("detailTitle")
                        .focused($focus, equals: .detailTitle)
                        .onSubmit { commitTitle() }
                    Button("Adı Kaydet") { commitTitle() }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Durumlar")
                        .font(.headline)
                    statusToggle("Kütüphanem", keyPath: \Game.isInLibrary, target: .statusLibrary, identifier: "status-library")
                    statusToggle("Wishlist", keyPath: \Game.isWishlisted, target: .statusWishlist, identifier: "status-wishlist")
                    statusToggle("Oynanacak", keyPath: \Game.isToPlay, target: .statusToPlay, identifier: "status-to-play")
                    statusToggle("Oynandı", keyPath: \Game.isPlayed, target: .statusPlayed, identifier: "status-played")
                    statusToggle("Bitti", keyPath: \Game.isCompleted, target: .statusCompleted, identifier: "status-completed")
                    Text("Durumlar birbirinden bağımsızdır; birini değiştirmek diğerini değiştirmez.")
                        .font(.footnote)
                        .foregroundStyle(ink.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Kişisel puan")
                        .font(.headline)
                    Menu {
                        Button("Puanı kaldır") { commitRating(nil) }
                        Divider()
                        ForEach(PersonalRating.menuValues, id: \.self) { rating in
                            Button("\(rating)/10") { commitRating(rating) }
                        }
                    } label: {
                        LabeledContent("Puan", value: GamePresentation.ratingLabel(game.rating))
                    }
                    .focused($focus, equals: .ratingMenu)
                    .accessibilityLabel("Kişisel puan")
                    .accessibilityValue(GamePresentation.ratingLabel(game.rating))
                }

                if game.releaseDate != nil || !game.platforms.isEmpty || game.source == "rawg" {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Katalog bilgisi")
                            .font(.headline)
                        if let releaseDate = game.releaseDate {
                            Text("Çıkış: \(releaseDate)")
                        }
                        if !game.platforms.isEmpty {
                            Text(game.platforms.joined(separator: ", "))
                                .foregroundStyle(ink.secondary)
                        }
                        if game.source == "rawg" {
                            Link("RAWG kaynağında görüntüle", destination: RAWGService.safeSourceURL(game.sourceURL))
                        }
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(Color(red: 0.72, green: 0.22, blue: 0.16))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .defaultFocus($focus, .detailTitle)
    }

    private func statusToggle(
        _ title: String,
        keyPath: ReferenceWritableKeyPath<Game, Bool>,
        target: LibraryFocusTarget,
        identifier: String
    ) -> some View {
        Toggle(title, isOn: Binding(
            get: { game[keyPath: keyPath] },
            set: { newValue in
                switch GameMutation.setStatus(game, keyPath: keyPath, value: newValue, save: persistEdit) {
                case .applied: errorMessage = nil
                case .rejected(let message), .saveFailed(let message): errorMessage = message
                }
            }
        ))
        .focused($focus, equals: target)
        .accessibilityIdentifier(identifier)
    }

    private func commitTitle() {
        switch GameMutation.rename(game, rawTitle: titleDraft, save: persistEdit) {
        case .applied:
            errorMessage = nil
            titleDraft = game.title
        case .rejected(let message), .saveFailed(let message):
            errorMessage = message
        }
    }

    private func commitRating(_ raw: Int?) {
        switch GameMutation.setRating(game, raw: raw, save: persistEdit) {
        case .applied:
            errorMessage = nil
        case .rejected(let message), .saveFailed(let message):
            errorMessage = message
        }
    }

    private func persistEdit() throws {
        #if DEBUG
        if Game_libraryApp.usesTestStorage && ProcessInfo.processInfo.arguments.contains("--ui-testing-edit-save-failure") {
            throw CocoaError(.fileWriteUnknown)
        }
        #endif
        try modelContext.save()
    }
}

private struct AddGameSheet: View {
    let onOpen: (Game) -> Void
    let onClose: () -> Void
    let onBulkStart: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(CatalogImporter.self) private var importer
    @Query private var importProgress: [CatalogImportProgress]
    @Environment(\.colorScheme) private var colorScheme
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
    @FocusState private var focus: LibraryFocusTarget?

    private var ink: ShelfInk { ShelfInk(scheme: colorScheme) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Oyun Ekle")
                        .font(.title2.weight(.semibold))
                    Spacer()
                    Button("Gizle", action: onClose)
                }

                if !manualEntryOnly {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("RAWG kataloğunda ara")
                            .font(.headline)
                        TextField("Aranacak oyun adı", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityIdentifier("searchTitle")
                            .onSubmit { startSearch() }
                        HStack {
                            Button("Ara") { startSearch() }
                                .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || search.isSearching || importer.isRunning)
                                .buttonStyle(.borderedProminent)
                            Button("API Anahtarını Ayarla") { isShowingKeyEditor = true }
                            Link("RAWG kaynağı", destination: RAWGService.attributionURL)
                        }
                        if apiKey.isEmpty {
                            Text("Katalog araması için RAWG API anahtarınızı ayarlayın. Elle ekleme her zaman kullanılabilir.")
                                .font(.footnote)
                                .foregroundStyle(ink.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if search.isSearching { ProgressView("RAWG aranıyor…") }
                        if let message = search.errorMessage {
                            Text(message).foregroundStyle(Color(red: 0.72, green: 0.22, blue: 0.16))
                            Button("Tekrar dene") { requestTask = Task { await search.retry(apiKey: apiKey) } }
                                .disabled(search.isSearching || importer.isRunning)
                        }
                        if search.hasSearched, search.results.isEmpty, !search.isSearching, search.errorMessage == nil {
                            Text("Sonuç bulunamadı. Aradığınız adla elle ekleyebilirsiniz.")
                        }
                        if !search.results.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(search.results) { result in
                                    HStack(alignment: .top, spacing: 12) {
                                        CatalogCover(urlString: result.artwork?.url.absoluteString, width: 44, ink: ink)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(result.name).font(.headline)
                                            if let released = result.released { Text("Çıkış: \(released)").font(.caption) }
                                            if !result.platformNames.isEmpty {
                                                Text(result.platformNames.joined(separator: ", ")).font(.caption).foregroundStyle(ink.secondary)
                                            }
                                            Link("RAWG kaynağı", destination: result.sourceURL).font(.caption)
                                        }
                                        Spacer(minLength: 8)
                                        Button(selectedResult?.id == result.id ? "Seçildi" : "Seç") { selectedResult = result }
                                    }
                                    .padding(.vertical, 8)
                                    .overlay(alignment: .bottom) {
                                        Rectangle().fill(ink.hairline).frame(height: 1)
                                    }
                                }
                            }
                        }
                        if let selectedResult {
                            Button("Seçilen Oyunu Ekle") {
                                do { try add(GameDraft.rawg(selectedResult)) }
                                catch { errorMessage = "Yerel kayıt tamamlanamadı. Seçiminiz korunuyor; tekrar deneyebilirsiniz." }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        if search.hasNextPage {
                            Button("Sonraki 20 sonucu yükle") { requestTask = Task { await search.loadNext(apiKey: apiKey) } }
                                .disabled(search.isSearching || importer.isRunning)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Elle ekle")
                        .font(.headline)
                    TextField("Oyun adı", text: $manualTitle)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("manualTitle")
                        .focused($focus, equals: .addManualTitle)
                    Button("Elle Ekle") {
                        switch GameMutation.manualDraft(from: manualTitle) {
                        case .ok(let draft):
                            do { try add(draft) }
                            catch { errorMessage = "Yerel kayıt tamamlanamadı. Girdiğiniz ad korunuyor; tekrar deneyebilirsiniz." }
                        case .rejected(let message):
                            errorMessage = message
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .focused($focus, equals: .addManualSubmit)
                    Text("Elle ekleme çevrimdışı da çalışır.")
                        .font(.footnote)
                        .foregroundStyle(ink.secondary)
                    Button(manualEntryOnly ? "Katalogda ara" : "Yalnızca elle ekle") {
                        manualEntryOnly.toggle()
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Otomatik katalog aktarımı").font(.headline)
                    Text("Tek komutla sayfa sayfa aktarır. Her çalıştırma en fazla 100 istek yapar; kota hatasında durur. Kişisel durumlar ve puanlar değişmez. Elle kayıtlarla aynı adlı oyunlar ayrı eklenir. Paneli gizlemek aktarımı durdurur.")
                        .font(.footnote)
                        .foregroundStyle(ink.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Link("RAWG kaynağı", destination: RAWGService.attributionURL)
                    if let progress = importProgress.first {
                        Text("\(progress.importedCount) oyun aktarıldı · Sıradaki sayfa: \(progress.nextPage)")
                            .font(.caption)
                            .accessibilityIdentifier("bulkProgress")
                    }
                    if importer.isRunning {
                        ProgressView("Katalog aktarılıyor…")
                        Button("Aktarımı Durdur") { importer.stop() }
                            .accessibilityIdentifier("bulkStop")
                    } else if importProgress.first?.isComplete != true {
                        Button(importProgress.first == nil ? "Kataloğu Aktar" : "Aktarımı Sürdür") {
                            requestTask?.cancel()
                            onBulkStart()
                            importer.start(container: modelContext.container, apiKey: apiKey)
                        }
                        .accessibilityIdentifier("bulkStart")
                        .disabled(search.isSearching)
                    }
                    if let message = importer.message, importProgress.first?.isComplete != true { Text(message).font(.footnote) }
                    if let error = importer.errorMessage {
                        Text(error).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
                    }
                    if importProgress.first?.isComplete == true && !importer.isRunning {
                        Text("Katalog aktarımı tamamlandı.").font(.footnote)
                        Button("Baştan Tara") {
                            onBulkStart()
                            importer.start(container: modelContext.container, apiKey: apiKey, restart: true)
                        }
                        .disabled(search.isSearching)
                        .accessibilityIdentifier("bulkRestart")
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(Color(red: 0.72, green: 0.22, blue: 0.16))
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let pendingDraft {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Aynı adlı oyun zaten var")
                            .font(.headline)
                        Text("Mevcut kaydı açın veya bunun ayrı bir oyun olduğunu onaylayın.")
                            .foregroundStyle(ink.secondary)
                        ForEach(nameMatches) { game in
                            Button("Mevcut kaydı aç: \(game.title)") { onOpen(game) }
                        }
                        Button("Ayrı Oyun Olarak Ekle") {
                            do { try add(pendingDraft, confirmed: true) }
                            catch { errorMessage = "Yerel kayıt tamamlanamadı. Lütfen tekrar deneyin." }
                        }
                        Button("Vazgeç") { self.pendingDraft = nil; nameMatches = [] }
                    }
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .popover(isPresented: $isShowingKeyEditor) {
            APIKeySheet { apiKey = $0 }
        }
        .task {
            do { apiKey = try KeychainStore.loadRAWGKey() ?? "" }
            catch { errorMessage = "Kaydedilmiş API anahtarı okunamadı. Elle ekleme kullanılabilir." }
        }
        .onDisappear { requestTask?.cancel(); importer.stop() }
        .onChange(of: manualTitle) { pendingDraft = nil; nameMatches = [] }
        .onChange(of: selectedResult) { pendingDraft = nil; nameMatches = [] }
        .onChange(of: searchText) { pendingDraft = nil; nameMatches = [] }
    }

    private func startSearch() {
        guard !search.isSearching, !importer.isRunning else { return }
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
        VStack(alignment: .leading, spacing: 12) {
            Text("RAWG API Anahtarı")
                .font(.headline)
            SecureField("RAWG API anahtarı", text: $key)
                .textFieldStyle(.roundedBorder)
            Text("Anahtar yalnızca bu Mac'in Keychain'inde saklanır; oyun kayıtlarına veya günlük kaydına yazılmaz.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            HStack {
                Button("Vazgeç") { dismiss() }
                Spacer()
                Button("Kaydet") { save() }
                    .disabled(key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 360)
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

#Preview {
    ContentView().environment(CatalogImporter())
        .modelContainer(for: [Game.self, CatalogImportProgress.self], inMemory: true)
}
