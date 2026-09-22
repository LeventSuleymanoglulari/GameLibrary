//
//  GamePresentation.swift
//  Game library
//

import Foundation

enum GamePresentation {
    static let emptyTitleMessage = "Oyun adı boş olamaz. Bir ad yazıp tekrar deneyin."
    static let ratingOutOfScaleMessage = "Puan 1 ile 10 arasında olmalıdır."
    static let saveFailedMessage = "Değişiklik kaydedilemedi. Lütfen tekrar deneyin."
    static let detailDismissTitle = "Kapat"
    static let detailDismissIdentifier = "detailDismiss"
    static let emptyFilteredTabDescription = "Bu sekmede henüz oyun yok. Bir oyunu açıp durumunu seçebilirsiniz."

    static func statusLabels(for game: Game) -> [String] {
        [
            game.isInLibrary ? "Kütüphane" : nil,
            game.isWishlisted ? "Wishlist" : nil,
            game.isToPlay ? "Oynanacak" : nil,
            game.isPlayed ? "Oynandı" : nil,
            game.isCompleted ? "Bitti" : nil
        ].compactMap { $0 }
    }

    static func ratingLabel(_ rating: Int?) -> String {
        rating.map { "\($0)/10" } ?? "Verilmedi"
    }

    static func ratingChip(_ rating: Int?) -> String? {
        rating.map { "Puan: \($0)/10" }
    }

    static func accessibilityValue(for game: Game) -> String {
        (statusLabels(for: game) + (ratingChip(game.rating).map { [$0] } ?? [])).joined(separator: ", ")
    }

    static func message(for error: LibraryInputError) -> String {
        switch error {
        case .emptyTitle: emptyTitleMessage
        case .ratingOutOfScale: ratingOutOfScaleMessage
        }
    }
}
