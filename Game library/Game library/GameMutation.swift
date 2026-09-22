//
//  GameMutation.swift
//  Game library
//

import Foundation

enum GameMutation: Sendable {
    enum Outcome: Equatable, Sendable {
        case applied
        case rejected(message: String)
        case saveFailed(message: String)
    }

    enum ManualDraftResult: Equatable {
        case ok(GameDraft)
        case rejected(message: String)
    }

    @MainActor static func setStatus(
        _ game: Game, keyPath: ReferenceWritableKeyPath<Game, Bool>, value: Bool,
        save: () throws -> Void
    ) -> Outcome {
        let previous = game[keyPath: keyPath]
        game[keyPath: keyPath] = value
        do { try save(); return .applied }
        catch {
            game[keyPath: keyPath] = previous
            return .saveFailed(message: GamePresentation.saveFailedMessage)
        }
    }

    @MainActor
    static func rename(
        _ game: Game,
        rawTitle: String,
        save: () throws -> Void
    ) -> Outcome {
        let title: GameTitle
        do {
            title = try GameTitle(raw: rawTitle)
        } catch {
            return .rejected(message: GamePresentation.emptyTitleMessage)
        }
        let previous = game.title
        game.title = title.value
        do {
            try save()
            return .applied
        } catch {
            game.title = previous
            return .saveFailed(message: GamePresentation.saveFailedMessage)
        }
    }

    @MainActor
    static func setRating(
        _ game: Game,
        raw: Int?,
        save: () throws -> Void
    ) -> Outcome {
        let rating: PersonalRating
        do {
            rating = try PersonalRating(raw: raw)
        } catch {
            return .rejected(message: GamePresentation.ratingOutOfScaleMessage)
        }
        let previous = game.rating
        game.rating = rating.storedValue
        do {
            try save()
            return .applied
        } catch {
            game.rating = previous
            return .saveFailed(message: GamePresentation.saveFailedMessage)
        }
    }

    static func manualDraft(from rawTitle: String) -> ManualDraftResult {
        let title: GameTitle
        do {
            title = try GameTitle(raw: rawTitle)
        } catch {
            return .rejected(message: GamePresentation.emptyTitleMessage)
        }
        do {
            return .ok(try GameDraft.manual(title.value))
        } catch {
            return .rejected(message: GamePresentation.emptyTitleMessage)
        }
    }
}
