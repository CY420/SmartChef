//
//  SmartChefApp.swift
//  SmartChef
//
//  Created by patrick on 2026/6/2.
//

import SwiftUI
import SwiftData

@main
struct SmartChefApp: App {
    @State private var viewModel = SmartChefViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(viewModel)
        }
        // 🚨 修正處：傳入 [Ingredient.self, ShoppingItem.self] 陣列
        .modelContainer(for: [Ingredient.self, ShoppingItem.self])
    }
}
