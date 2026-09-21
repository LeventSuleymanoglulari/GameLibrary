//
//  Game.swift
//  Game library
//

import Foundation
import SwiftData

@Model
final class Game {
    var title: String
    var addedDate: Date

    // Bu alanlar 3. aşamada düzenleme arayüzüne bağlanacaktır. Dört sekme
    // şimdiden aynı kayıtları filtrelediği için kayıtlar çoğaltılmaz.
    var isInLibrary: Bool
    var isWishlisted: Bool
    var isToPlay: Bool

    init(title: String, addedDate: Date = .now) {
        self.title = title
        self.addedDate = addedDate
        self.isInLibrary = false
        self.isWishlisted = false
        self.isToPlay = false
    }
}
