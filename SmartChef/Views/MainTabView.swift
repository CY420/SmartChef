//
//  MainTabView.swift
//  SmartChef
//
//  Created by 114-2Student03 on 2026/6/2.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            InventoryView()
                .tabItem {
                    Label("我的冰箱", systemImage: "refrigerator")
                }
            
            // 這裡會報錯是因為我們還沒建立這兩個 View，留待後續步驟完成
            ShoppingListView()
                .tabItem {
                    Label("購物清單", systemImage: "cart")
                }
            
            AIInspirationView()
                .tabItem {
                    Label("AI 廚房", systemImage: "sparkles.tv")
                }
        }
    }
}
