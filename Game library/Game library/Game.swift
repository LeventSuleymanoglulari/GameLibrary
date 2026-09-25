//
//  Game.swift
//  Game library
//

import Foundation
import SwiftData

enum LibraryPlatform: String, CaseIterable {
    case steam, epic, gog, pc, playstation, xbox, nintendoSwitch = "nintendo-switch", android, ios

    var title: String {
        switch self {
        case .steam: "Steam"
        case .epic: "Epic Games"
        case .gog: "GOG"
        case .pc: "PC"
        case .playstation: "PlayStation"
        case .xbox: "Xbox"
        case .nintendoSwitch: "Nintendo Switch"
        case .android: "Android"
        case .ios: "iOS"
        }
    }

    // İlk PR derlemesinde kaydedilmiş etiketleri de okuyabilmek için sabit eşleme.
    static func resolve(_ stored: String?) -> Self? {
        guard let stored else { return nil }
        if let platform = Self(rawValue: stored) { return platform }
        let legacy: [String: Self] = [
            "Steam": .steam, "Epic Games": .epic, "GOG": .gog, "PC": .pc,
            "PlayStation": .playstation, "Xbox": .xbox, "Nintendo Switch": .nintendoSwitch,
            "Android": .android, "iOS": .ios
        ]
        return legacy[stored]
    }
}

@Model
final class Game {
    var title: String
    var addedDate: Date
    var source: String = "manual"
    var externalID: Int?
    var sourceURL: String?
    var releaseDate: String?
    var platforms: [String] = []

    // Dört sekme aynı kayıtları filtreler; durumlar birbirinden bağımsızdır.
    var isInLibrary: Bool = false
    var isWishlisted: Bool = false
    var isToPlay: Bool = false
    var isPlayed: Bool = false
    var isCompleted: Bool = false
    var isFavorite: Bool = false
    var storePlatform: String?
    var rating: Int?
    var artworkURL: String?

    init(
        title: String,
        addedDate: Date = .now,
        source: String = "manual",
        externalID: Int? = nil,
        sourceURL: String? = nil,
        releaseDate: String? = nil,
        platforms: [String] = []
    ) {
        self.title = title
        self.addedDate = addedDate
        self.source = source
        self.externalID = externalID
        self.sourceURL = sourceURL
        self.releaseDate = releaseDate
        self.platforms = platforms
        self.isInLibrary = false
        self.isWishlisted = false
        self.isToPlay = false
        self.isPlayed = false
        self.isCompleted = false
        self.rating = nil
    }
}

struct GameDraft: Equatable {
    let title: String
    let catalog: RAWGGame?

    static func manual(_ title: String) throws -> Self {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw RAWGServiceError.invalidResponse }
        return Self(title: title, catalog: nil)
    }

    static func rawg(_ game: RAWGGame) throws -> Self {
        guard game.id > 0, !game.name.isEmpty else { throw RAWGServiceError.invalidResponse }
        return Self(title: game.name, catalog: game)
    }

    private init(title: String, catalog: RAWGGame?) {
        self.title = title
        self.catalog = catalog
    }
}

enum AddGameResult {
    case added(Game), existing(Game), sameName([Game])
}

enum DestroyOutcome: Equatable, Sendable {
    case destroyed
    case saveFailed(message: String)
}

extension Game {
    @MainActor static func add(
        _ draft: GameDraft, to context: ModelContext, allowSameName: Bool = false,
        save: (() throws -> Void)? = nil
    ) throws -> AddGameResult {
        let games = try context.fetch(FetchDescriptor<Game>())
        if let catalog = draft.catalog,
           let existing = games.first(where: { $0.source == "rawg" && $0.externalID == catalog.id }) {
            return .existing(existing)
        }
        let matches = games.filter {
            $0.title.trimmingCharacters(in: .whitespacesAndNewlines)
                .compare(draft.title, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
        if !allowSameName, !matches.isEmpty { return .sameName(matches) }
        let game = Game(title: draft.title, source: draft.catalog == nil ? "manual" : "rawg",
                        externalID: draft.catalog?.id, sourceURL: draft.catalog?.sourceURL.absoluteString,
                        releaseDate: draft.catalog?.released, platforms: draft.catalog?.platformNames ?? [])
        game.artworkURL = draft.catalog?.artwork?.url.absoluteString
        context.insert(game)
        do {
            if let save { try save() } else { try context.save() }
        }
        catch { context.delete(game); throw error }
        return .added(game)
    }

    @MainActor
    static func destroy(
        _ game: Game,
        from context: ModelContext,
        save: (() throws -> Void)? = nil
    ) -> DestroyOutcome {
        if game.isDeleted || game.modelContext == nil {
            return .destroyed
        }
        context.delete(game)
        do {
            if let save { try save() } else { try context.save() }
            return .destroyed
        } catch {
            context.rollback()
            return .saveFailed(message: GamePresentation.saveFailedMessage)
        }
    }
}
