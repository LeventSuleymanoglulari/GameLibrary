//
//  Item.swift
//  Game library
//
//  Created by Levent Suleymanoglulari on 20/09/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
