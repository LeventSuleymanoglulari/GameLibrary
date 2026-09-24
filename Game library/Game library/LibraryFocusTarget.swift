//
//  LibraryFocusTarget.swift
//  Game library
//

import Foundation

enum LibraryFocusTarget: Hashable {
    case detailTitle
    case statusLibrary
    case statusWishlist
    case statusToPlay
    case statusPlayed
    case statusCompleted
    case ratingMenu
    case dismissDetail
    case addManualTitle
    case addManualSubmit
    case searchTitle
    case selectResult(Int)
    case confirmSelected
}
