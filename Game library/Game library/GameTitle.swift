//
//  GameTitle.swift
//  Game library
//

import Foundation

struct GameTitle: Hashable, Sendable {
    let value: String

    init(raw: String) throws {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw LibraryInputError.emptyTitle }
        value = trimmed
    }
}
