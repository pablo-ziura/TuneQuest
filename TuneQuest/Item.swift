//
//  Item.swift
//  TuneQuest
//
//  Created by Pablo Ruiz Arnal on 28/7/25.
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
