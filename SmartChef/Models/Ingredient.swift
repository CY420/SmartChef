//
//  Untitled.swift
//  SmartChef
//
//  Created by patrick on 2026/6/2.
//

import Foundation
import SwiftData

@Model
final class Ingredient {
    var id: UUID
    var name: String
    var category: String
    var expiryDate: Date
    var quantity: Double
    var unit: String
    var storageLocation: String // 💡 新增：儲存位置 ("冷藏", "冷凍", "乾貨")
    var isStaple: Bool
    var notes: String
    
    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        expiryDate: Date,
        quantity: Double,
        unit: String,
        storageLocation: String = "冷藏", // 💡 設定預設值
        isStaple: Bool = false,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.expiryDate = expiryDate
        self.quantity = quantity
        self.unit = unit
        self.storageLocation = storageLocation
        self.isStaple = isStaple
        self.notes = notes
    }
}
