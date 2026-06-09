//
//  DesignSystem.swift
//  SmartChef
//
//  Created by patrick on 2026/6/5.
//

import SwiftUI

// MARK: - 🌌 高級環境光暈背景
struct AmbientBackground: View {
    var body: some View {
        ZStack {
            // 底色
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            // 點綴光暈 1：暖橘色
            GeometryReader { proxy in
                Circle()
                    .fill(Color.orange.opacity(0.5))
                    .frame(width: proxy.size.width * 0.9)
                    .position(x: proxy.size.width * 0.2, y: 0)
                    .blur(radius: 100)
                
                // 點綴光暈 2：科技藍
                Circle()
                    .fill(Color.blue.opacity(0.5))
                    .frame(width: proxy.size.width * 0.9)
                    .position(x: proxy.size.width * 0.8, y: proxy.size.height)
                    .blur(radius: 100)
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - 🏷️ 客製化置中大標題導航列
struct CustomHeaderView<Leading: View, Trailing: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let leadingContent: Leading
    @ViewBuilder let trailingContent: Trailing
    
    var body: some View {
        HStack(alignment: .center) {
            // 左側操作區 (設定固定寬度以確保中間標題絕對置中)
            leadingContent
                .frame(width: 44, alignment: .leading)
            
            Spacer()
            
            // 中央雙層標題
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.6))
                        .tracking(3) // 💡 增加字距，營造精品雜誌感
                }
            }
            
            Spacer()
            
            // 右側操作區
            trailingContent
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}
