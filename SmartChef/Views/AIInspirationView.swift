//
//  AIInspirationView.swift
//  SmartChef
//
//  Created by patrick on 2026/6/2.
//

import SwiftUI
import SwiftData
import Kingfisher

struct AIInspirationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SmartChefViewModel.self) private var viewModel
    @Query private var ingredients: [Ingredient]
    
    @State private var selectedIngredientIDs: Set<UUID> = []
    @State private var showingRecipeCover: Bool = false
    
    @Namespace private var capsuleAnimation
    
    var selectedIngredients: [Ingredient] {
        ingredients.filter { selectedIngredientIDs.contains($0.id) }
    }
    var unselectedIngredients: [Ingredient] {
        ingredients.filter { !selectedIngredientIDs.contains($0.id) }
    }
    
    var nlpKeywords: [String] {
        let allNotes = selectedIngredients.map { $0.notes }.joined(separator: " ")
        return Array(Set(viewModel.extractKeywords(from: allNotes)))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 🌌 高級環境光暈背景
                AmbientBackground()
                
                VStack(spacing: 0) {
                    // 🏷️ 客製化置中大標題導航列
                    CustomHeaderView(
                        title: "星級私房菜",
                        subtitle: "AI CHEF PLATFORM",
                        leadingContent: { Spacer() },
                        trailingContent: { Spacer() }
                    )
                    
                    if ingredients.isEmpty {
                        ContentUnavailableView("庫存空虛", systemImage: "takeoutbox", description: Text("請先到我的冰箱新增食材。"))
                    } else {
                        // 💡 修正排版：改用 ZStack 讓 ScrollView 佔滿 100% 畫面，按鈕則懸浮在底部
                        ZStack(alignment: .bottom) {
                            
                            // 📜 滿版捲動區域
                            ScrollView(showsIndicators: false) {
                                VStack(spacing: 24) {
                                    
                                    // 🍲 備料大釜
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("🍲 備料大釜")
                                            .font(.title3.bold())
                                            .foregroundColor(.primary)
                                        
                                        ZStack(alignment: .topLeading) {
                                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .fill(Color(.tertiarySystemGroupedBackground))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                        .strokeBorder(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
                                                )
                                                .frame(minHeight: 100)
                                            
                                            if selectedIngredients.isEmpty {
                                                Text("點擊下方的食材加入大釜中...")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                    .padding()
                                            } else {
                                                TagCloudLayout(spacing: 10) {
                                                    ForEach(selectedIngredients) { ingredient in
                                                        IngredientCapsule(ingredient: ingredient, isSelected: true)
                                                            .matchedGeometryEffect(id: ingredient.id, in: capsuleAnimation)
                                                            .onTapGesture {
                                                                toggleSelection(for: ingredient)
                                                            }
                                                    }
                                                }
                                                .padding(12)
                                            }
                                        }
                                    }
                                    
                                    // ✨ NLP 魔法星光標籤
                                    if !nlpKeywords.isEmpty {
                                        HStack {
                                            Image(systemName: "sparkles")
                                                .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.1))
                                            Text("已自動為您加入隱藏調味：\(nlpKeywords.joined(separator: "、"))")
                                                .font(.caption.bold())
                                                .foregroundColor(.primary)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Capsule())
                                        .shadow(color: Color(red: 1.0, green: 0.75, blue: 0.1).opacity(0.3), radius: 8, y: 2)
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                    }
                                    
                                    // ☁️ 泡泡標籤池
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("📦 庫存標籤池")
                                            .font(.title3.bold())
                                            .foregroundColor(.primary)
                                        
                                        TagCloudLayout(spacing: 10) {
                                            ForEach(unselectedIngredients) { ingredient in
                                                IngredientCapsule(ingredient: ingredient, isSelected: false)
                                                    .matchedGeometryEffect(id: ingredient.id, in: capsuleAnimation)
                                                    .onTapGesture {
                                                        toggleSelection(for: ingredient)
                                                    }
                                                    .modifier(JiggleEffect(isActive: daysToExpiry(for: ingredient) <= 3))
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                // 💡 加入底部緩衝帶，確保滑到最下面時，標籤不會被按鈕蓋住
                                .padding(.bottom, 120)
                            }
                            
                            // 🕹️ 固定懸浮生成按鈕
                            Button {
                                showingRecipeCover = true
                                Task {
                                    await viewModel.generateRecipe(using: selectedIngredients)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "wand.and.stars")
                                    Text(selectedIngredients.isEmpty ? "請至少加入一項食材" : "AI 點石成金")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedIngredients.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                                .cornerRadius(16)
                                .shadow(color: selectedIngredients.isEmpty ? .clear : .blue.opacity(0.4), radius: 10, y: 5)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24) // 讓按鈕微微浮起
                            .disabled(selectedIngredients.isEmpty)
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showingRecipeCover) {
                RecipeResultView()
            }
        }
    }
    
    private func toggleSelection(for ingredient: Ingredient) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.interpolatingSpring(stiffness: 250, damping: 20)) {
            if selectedIngredientIDs.contains(ingredient.id) {
                selectedIngredientIDs.remove(ingredient.id)
            } else {
                selectedIngredientIDs.insert(ingredient.id)
            }
        }
    }
    
    private func daysToExpiry(for ingredient: Ingredient) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: ingredient.expiryDate)).day ?? 0
    }
}

// MARK: - 💊 精緻圓角膠囊 (Ingredient Capsule)
struct IngredientCapsule: View {
    let ingredient: Ingredient
    let isSelected: Bool
    
    var daysToExpiry: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: ingredient.expiryDate)).day ?? 0
    }
    
    var statusColor: Color {
        if daysToExpiry < 0 { return Color(.systemRed) }
        if daysToExpiry <= 3 { return .orange }
        return .green
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(ingredient.name)
                .font(.subheadline.weight(.medium))
                .foregroundColor(isSelected ? .white : .primary)
            
            if ingredient.quantity != 1.0 {
                Text("\(ingredient.quantity.formatted())\(ingredient.unit)")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
        )
        .overlay(
            Capsule()
                .strokeBorder(isSelected ? Color.white.opacity(0.3) : statusColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - 🫨 Jiggle 抖動修飾器
struct JiggleEffect: ViewModifier {
    let isActive: Bool
    @State private var isJiggling = false
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isActive && isJiggling ? 2.5 : -2.5))
            .onAppear {
                if isActive {
                    withAnimation(.easeInOut(duration: 0.12).repeatForever(autoreverses: true)) {
                        isJiggling = true
                    }
                }
            }
    }
}

// MARK: - ☁️ iOS 16+ 泡泡標籤池專用 Layout
@available(iOS 16.0, *)
struct TagCloudLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 400, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for row in result.rows {
            for element in row.elements {
                let x = bounds.minX + element.rect.minX
                let y = bounds.minY + element.rect.minY
                subviews[element.index].place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            }
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var rows: [Row] = []
        
        struct Row {
            var elements: [(index: Int, rect: CGRect)] = []
            var size: CGSize = .zero
        }
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentRow = Row()
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            
            for (index, subview) in subviews.enumerated() {
                let size = subview.sizeThatFits(.unspecified)
                if currentX + size.width > maxWidth, !currentRow.elements.isEmpty {
                    rows.append(currentRow)
                    currentY += currentRow.size.height + spacing
                    currentRow = Row()
                    currentX = 0
                }
                
                currentRow.elements.append((index, CGRect(x: currentX, y: currentY, width: size.width, height: size.height)))
                currentRow.size.width = currentX + size.width
                currentRow.size.height = max(currentRow.size.height, size.height)
                
                currentX += size.width + spacing
            }
            if !currentRow.elements.isEmpty {
                rows.append(currentRow)
                currentY += currentRow.size.height
            }
            self.size = CGSize(width: maxWidth, height: currentY)
        }
    }
}

// MARK: - 👨‍🍳 雙層英雄卡 (Recipe Result View)
struct RecipeResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SmartChefViewModel.self) private var viewModel
    
    let warmYellow = Color(red: 1.0, green: 0.75, blue: 0.1)
    
    var body: some View {
        GeometryReader { screenProxy in
            ZStack(alignment: .top) {
                Color(.systemBackground).ignoresSafeArea()
                
                if viewModel.isGeneratingRecipe {
                    VStack(spacing: 24) {
                        ProgressView()
                            .scaleEffect(1.8)
                            .tint(warmYellow)
                        Text("主廚正在利用 Gemini 融合食材精華...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            // 📸 上層：視覺衝擊
                            GeometryReader { geometry in
                                if let url = viewModel.recipeImageURL {
                                    KFImage(url)
                                        .resizable()
                                        .placeholder {
                                            Rectangle().fill(Color(.systemGray6))
                                                .overlay(ProgressView())
                                        }
                                        .scaledToFill()
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                        .clipped()
                                        .overlay(
                                            LinearGradient(
                                                colors: [Color(.systemBackground).opacity(0), Color(.systemBackground)],
                                                startPoint: .center,
                                                endPoint: .bottom
                                            )
                                        )
                                }
                            }
                            .frame(height: screenProxy.size.height * 0.4)
                            
                            // 📖 下層：雜誌風排版
                            VStack(alignment: .leading, spacing: 20) {
                                if let recipeText = viewModel.generatedRecipe {
                                    MagazineRecipeText(text: recipeText, brandColor: warmYellow)
                                } else {
                                    Text("無可用食譜資訊")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 60)
                            .offset(y: -40)
                        }
                    }
                    .ignoresSafeArea(edges: .top)
                }
                
                // 獨立關閉按鈕
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                            .clipShape(Circle())
                    }
                    .disabled(viewModel.isGeneratingRecipe)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, screenProxy.safeAreaInsets.top > 0 ? screenProxy.safeAreaInsets.top + 10 : 50)
            }
        }
    }
}

// MARK: - 📰 專屬 Markdown 雜誌風排版解析器
struct MagazineRecipeText: View {
    let text: String
    let brandColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            let lines = text.components(separatedBy: .newlines)
            
            ForEach(0..<lines.count, id: \.self) { index in
                let line = lines[index]
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                
                if trimmed.isEmpty {
                    // 忽略空行
                }
                else if isCookingStep(trimmed), let parsed = parseStep(trimmed) {
                    HStack(alignment: .top, spacing: 14) {
                        Text(parsed.0)
                            .font(.system(size: 46, weight: .heavy, design: .serif))
                            .foregroundColor(brandColor)
                            .offset(y: -6)
                        
                        Text(LocalizedStringKey(parsed.1))
                            .font(.body)
                            .lineSpacing(6)
                            .foregroundColor(.primary)
                            .padding(.top, 4)
                    }
                }
                else if trimmed.hasPrefix("### ") || trimmed.hasPrefix("## ") || trimmed.hasPrefix("# ") {
                    let cleanTitle = trimmed.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespaces)
                    Text(LocalizedStringKey(cleanTitle))
                        .font(.title.weight(.heavy))
                        .padding(.top, 16)
                }
                else if trimmed.hasPrefix("#### ") {
                    let cleanSub = trimmed.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespaces)
                    Text(LocalizedStringKey(cleanSub))
                        .font(.title3.bold())
                        .foregroundColor(brandColor)
                        .padding(.top, 8)
                }
                else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(brandColor)
                            .frame(width: 6, height: 6)
                            .padding(.top, 8)
                        Text(LocalizedStringKey(String(trimmed.dropFirst(2))))
                            .font(.body)
                            .foregroundColor(.primary.opacity(0.85))
                    }
                }
                else {
                    Text(LocalizedStringKey(trimmed))
                        .font(.body)
                        .lineSpacing(6)
                        .foregroundColor(.primary.opacity(0.85))
                }
            }
        }
    }
    
    private func isCookingStep(_ line: String) -> Bool {
        guard let dotIndex = line.firstIndex(of: ".") else { return false }
        let prefix = line[..<dotIndex].trimmingCharacters(in: .whitespaces)
        return Int(prefix) != nil
    }
    
    private func parseStep(_ line: String) -> (String, String)? {
        guard let dotIndex = line.firstIndex(of: ".") else { return nil }
        let prefix = String(line[..<dotIndex]).trimmingCharacters(in: .whitespaces)
        guard Int(prefix) != nil else { return nil }
        let suffix = String(line[line.index(after: dotIndex)...]).trimmingCharacters(in: .whitespaces)
        return (prefix, suffix)
    }
}
