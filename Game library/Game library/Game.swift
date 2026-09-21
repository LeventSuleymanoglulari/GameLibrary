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
    var source: String
    var externalID: Int?
    var sourceURL: String?
    var releaseDate: String?
    var platforms: [String]

    // Bu alanlar 3. aşamada düzenleme arayüzüne bağlanacaktır. Dört sekme
    // şimdiden aynı kayıtları filtrelediği için kayıtlar çoğaltılmaz.
    var isInLibrary: Bool
    var isWishlisted: Bool
    var isToPlay: Bool

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
    }
}
