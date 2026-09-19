//
//  Game.swift
//  Game library
//
//  Created by Levent Suleymanoglulari on 20/09/2026.
//

import Foundation
import SwiftData

enum Platform: String, CaseIterable, Codable {
    case steam = "Steam"
    case epicGames = "Epic Games"
    case playStation = "PlayStation"
    case xbox = "Xbox"
    case nintendoSwitch = "Nintendo Switch"
    case pc = "PC"
    case macOS = "macOS"
    case iOS = "iOS"
}

enum GameStatus: String, CaseIterable, Codable {
    case backlog = "Backlog"
    case playing = "Playing"
    case completed = "Completed"
    case abandoned = "Abandoned"
}

@Model
final class Game {
    var title: String
    var platformRaw: String
    var statusRaw: String
    var addedDate: Date
    var notes: String?

    init(title: String,
         platform: Platform,
         status: GameStatus = .backlog,
         addedDate: Date = .now,
         notes: String? = nil) {
        self.title = title
        self.platformRaw = platform.rawValue
        self.statusRaw = status.rawValue
        self.addedDate = addedDate
        self.notes = notes
    }

    var platform: Platform {
        get { Platform(rawValue: platformRaw) ?? .pc }
        set { platformRaw = newValue.rawValue }
    }

    var status: GameStatus {
        get { GameStatus(rawValue: statusRaw) ?? .backlog }
        set { statusRaw = newValue.rawValue }
    }
}
