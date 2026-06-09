//
//  ShoppingItem.swift
//  SmartChef
//
//  Created by patrick on 2026/6/2.
//

import Foundation
import SwiftData

@Model
final class ShoppingItem {
    var name: String
    var category: String
    var targetExpiryDate: Date
    var quantity: Double
    var unit: String
    var isPurchased: Bool = false
    var isStaple: Bool = false
    var notes: String = "" // 💡 確保有這個屬性
    var addedDate: Date = Date()
    
    init(name: String, category: String, targetExpiryDate: Date = Date().addingTimeInterval(86400 * 7), quantity: Double, unit: String, isStaple: Bool = false, notes: String = "") {
        self.name = name
        self.category = category
        self.targetExpiryDate = targetExpiryDate
        self.quantity = quantity
        self.unit = unit
        self.isStaple = isStaple
        self.notes = notes
    }
}
