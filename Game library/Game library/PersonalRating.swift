//
//  PersonalRating.swift
//  Game library
//

import Foundation

enum PersonalRating: Hashable, Sendable {
    case none
    case score(Int)

    static var validScale: ClosedRange<Int> { 1...10 }

    static var menuValues: [Int] { Array(validScale) }

    init(raw: Int?) throws {
        guard let raw else {
            self = .none
            return
        }
        guard Self.validScale.contains(raw) else {
            throw LibraryInputError.ratingOutOfScale
        }
        self = .score(raw)
    }

    var storedValue: Int? {
        switch self {
        case .none: nil
        case .score(let value): value
        }
    }
}
