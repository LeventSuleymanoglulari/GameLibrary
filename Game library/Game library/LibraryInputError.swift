//
//  LibraryInputError.swift
//  Game library
//

import Foundation

enum LibraryInputError: Error, Equatable, Sendable {
    case emptyTitle
    case ratingOutOfScale
}
