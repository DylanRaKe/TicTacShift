//
//  Item.swift
//  TicTacShift
//
//  Created by Novalan on 8/29/25.
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
