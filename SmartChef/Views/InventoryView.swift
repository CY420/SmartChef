//
//  InventoryView.swift
//  SmartChef
//
//  Created by 114-2Student03 on 2026/6/2.
//

import SwiftUI
import SwiftData


// MARK: - 🧊 主要冰箱視圖
struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SmartChefViewModel.self) private var viewModel
    
    @Query private var ingredients: [Ingredient]
    
    @State private var showingAddSheet = false
    @State private var ingredientToDeduct: Ingredient? = nil
    @State private var ingredientToReplenish: Ingredient? = nil
    @State private var toastMessage: String? = nil
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()
                
                VStack(spacing: 0) {
                    CustomHeaderView(
                        title: "我的冰箱",
                        subtitle: "SMART INVENTORY",
                        leadingContent: {
                            Spacer()
                        },
                        trailingContent: {
                            Button { showingAddSheet = true } label: {
                                Image(systemName: "plus")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(color: .blue.opacity(0.3), radius: 5, y: 3)
                            }
                        }
                    )
                    
                    if ingredients.isEmpty {
                        ContentUnavailableView(
                            "冰箱空空的",
                            systemImage: "snowflake",
                            description: Text("點擊右上角新增食材，開始建立你的視覺儲存艙！")
                        )
                    } else {
                        ScrollView {
                            VStack(spacing: 24) {
                                DashboardRibbon(ingredients: ingredients)
                                    .padding(.top, 8)
                                
                                let calendar = Calendar.current
                                let startOfToday = calendar.startOfDay(for: Date())
                                
                                let expiredItems = ingredients.filter { calendar.dateComponents([.day], from: startOfToday, to: calendar.startOfDay(for: $0.expiryDate)).day ?? 0 < 0 }
                                let expiringSoonItems = ingredients.filter {
                                    let days = calendar.dateComponents([.day], from: startOfToday, to: calendar.startOfDay(for: $0.expiryDate)).day ?? 0
                                    return days >= 0 && days <= 3
                                }
                                let freshItems = ingredients.filter { calendar.dateComponents([.day], from: startOfToday, to: calendar.startOfDay(for: $0.expiryDate)).day ?? 0 > 3 }
                                
                                if !expiredItems.isEmpty {
                                    sectionContainer(title: "已過期", icon: "exclamationmark.triangle.fill", color: Color(.systemRed)) {
                                        LazyVGrid(columns: columns, spacing: 16) {
                                            ForEach(viewModel.sortIngredientsByUrgency(expiredItems)) { ingredient in
                                                buildGridCard(for: ingredient)
                                            }
                                        }
                                    }
                                }
                                
                                if !expiringSoonItems.isEmpty {
                                    sectionContainer(title: "即將過期 (3天內)", icon: "clock.badge.exclamationmark", color: .orange) {
                                        LazyVGrid(columns: columns, spacing: 16) {
                                            ForEach(viewModel.sortIngredientsByUrgency(expiringSoonItems)) { ingredient in
                                                buildGridCard(for: ingredient)
                                            }
                                        }
                                    }
                                }
                                
                                if !freshItems.isEmpty {
                                    sectionContainer(title: "新鮮食材", icon: "leaf.fill", color: .green) {
                                        LazyVGrid(columns: columns, spacing: 16) {
                                            ForEach(viewModel.sortIngredientsByUrgency(freshItems)) { ingredient in
                                                buildGridCard(for: ingredient)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 80)
                        }
                    }
                }
                
                if let message = toastMessage {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                            Text(message)
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(.ultraThickMaterial)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(1)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddSheet) { AddIngredientView() }
            .sheet(item: $ingredientToDeduct) { ingredient in
                DeductBottomSheet(ingredient: ingredient) { autoReplenishMsg in
                    // 💡 攔截「常備食材」耗盡時自動生成的 Toast 訊息
                    if let msg = autoReplenishMsg {
                        showToast(message: msg)
                    }
                }
                .presentationDetents([.fraction(0.45)])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $ingredientToReplenish) { ingredient in
                ReplenishBottomSheet(ingredient: ingredient) { successMessage in
                    showToast(message: successMessage)
                }
                .presentationDetents([.fraction(0.5)])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    private func showToast(message: String) {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            toastMessage = message
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                toastMessage = nil
            }
        }
    }
    
    @ViewBuilder
    private func sectionContainer(title: String, icon: String, color: Color, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
            }
            content()
        }
    }
    
    @ViewBuilder
    private func buildGridCard(for ingredient: Ingredient) -> some View {
        IngredientGridCard(ingredient: ingredient, onReplenish: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            ingredientToReplenish = ingredient
        }, onDeduct: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            ingredientToDeduct = ingredient
        })
    }
}

// MARK: - 📊 頂部動態儀表板
struct DashboardRibbon: View {
    var ingredients: [Ingredient]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                let calendar = Calendar.current
                let startOfToday = calendar.startOfDay(for: Date())
                
                let expiredCount = ingredients.filter { calendar.dateComponents([.day], from: startOfToday, to: calendar.startOfDay(for: $0.expiryDate)).day ?? 0 < 0 }.count
                let expiringSoonCount = ingredients.filter {
                    let days = calendar.dateComponents([.day], from: startOfToday, to: calendar.startOfDay(for: $0.expiryDate)).day ?? 0
                    return days >= 0 && days <= 3
                }.count
                
                if expiredCount > 0 { ribbonCapsule(icon: "bell.badge.fill", text: "\(expiredCount) 件過期", color: .red) }
                if expiringSoonCount > 0 { ribbonCapsule(icon: "flame.fill", text: "\(expiringSoonCount) 件急需消耗", color: .orange) }
                ribbonCapsule(icon: "shippingbox.fill", text: "共 \(ingredients.count) 件食材", color: .blue)
            }
            .padding(.horizontal, 2)
        }
    }
    
    private func ribbonCapsule(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - 📇 視覺化網格卡片
struct IngredientGridCard: View {
    let ingredient: Ingredient
    var onReplenish: () -> Void
    var onDeduct: () -> Void
    
    var daysToExpiry: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: ingredient.expiryDate)).day ?? 0
    }
    
    var isExpired: Bool { daysToExpiry < 0 }
    var isExpiringSoon: Bool { daysToExpiry >= 0 && daysToExpiry <= 3 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text(categoryEmoji(for: ingredient.category))
                    .font(.title2)
                    .padding(6)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(Circle())
                
                Spacer(minLength: 4)
                
                HStack(spacing: 4) {
                    // 💡 1. 視覺專屬標記：常備食材徽章
                    if ingredient.isStaple {
                        Text("常備")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .clipShape(Capsule())
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    
                    Text(ingredient.category)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.15))
                        .clipShape(Capsule())
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text(ingredient.storageLocation)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .font(.headline)
                    .foregroundColor(isExpired ? Color(.systemRed) : .primary)
                    .lineLimit(1)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(ingredient.quantity.formatted())
                        .font(.title3.bold())
                        .fontDesign(.rounded)
                        
                    Text(ingredient.unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(expiryText)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(statusColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(statusColor.opacity(0.1))
                .cornerRadius(6)
            
            Divider()
                .padding(.vertical, 2)
            
            HStack(spacing: 8) {
                Button(action: onReplenish) {
                    HStack(spacing: 4) {
                        Image(systemName: "cart.badge.plus")
                        Text("補貨")
                    }
                    .font(.caption.bold())
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(8)
                }
                
                Button(action: onDeduct) {
                    HStack(spacing: 4) {
                        Image(systemName: "minus.circle")
                        Text("消耗")
                    }
                    .font(.caption.bold())
                    .foregroundColor(Color(.systemRed))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color(.systemRed).opacity(0.08))
                    .cornerRadius(8)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isExpired ? Color(.systemRed).opacity(0.05) : Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            Group {
                if isExpiringSoon {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.clear, lineWidth: 1.5)
                        .phaseAnimator([false, true]) { content, phase in
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(colors: [.orange.opacity(phase ? 0.8 : 0.1), .red.opacity(phase ? 0.5 : 0.0)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 1.5
                                )
                        } animation: { _ in
                            .easeInOut(duration: 1.5)
                        }
                } else if isExpired {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color(.systemRed).opacity(0.5), lineWidth: 1.5)
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.green.opacity(0.4), lineWidth: 1.5)
                }
            }
        )
        .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
    }
    
    private func categoryEmoji(for category: String) -> String {
        switch category {
        case "蔬菜": return "🥬"; case "水果": return "🍎"; case "蛋奶": return "🥛"
        case "肉類": return "🥩"; case "海鮮": return "🐟"; case "調味料": return "🧂"
        case "飲品": return "🧃"; case "甜點": return "🍰"; default: return "🥫"
        }
    }
    
    private var statusColor: Color {
        if isExpired { return Color(.systemRed) }
        if isExpiringSoon { return .orange }
        return .green
    }
    
    private var expiryText: String {
        if isExpired { return "已過期 \(abs(daysToExpiry)) 天" }
        if daysToExpiry == 0 { return "今天到期" }
        return "剩餘 \(daysToExpiry) 天"
    }
}

// MARK: - 🛒 補貨設定抽屜
struct ReplenishBottomSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let ingredient: Ingredient
    var onComplete: (String) -> Void
    
    @State private var inputAmountString: String = "1"
    @State private var targetExpiryDate: Date = Date().addingTimeInterval(86400 * 7)
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray4))
                        .frame(width: 40, height: 5)
                        .padding(.top, 10)
                    
                    Text("補貨設定")
                        .font(.headline)
                    Text("準備採買：\(ingredient.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("預計購買數量")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                    
                    HStack(spacing: 12) {
                        TextField("1", text: $inputAmountString)
                            .keyboardType(.decimalPad)
                            .focused($isTextFieldFocused)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 8)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(isTextFieldFocused ? 0.5 : 0), lineWidth: 2)
                            )
                        
                        Text(ingredient.unit)
                            .font(.title3.bold())
                            .foregroundColor(.secondary)
                            .frame(width: 50, alignment: .leading)
                    }
                    .padding(.horizontal, 24)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    DatePicker("預計有效期限", selection: $targetExpiryDate, displayedComponents: .date)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                }
                
                Spacer()
                
                Button {
                    executeReplenish()
                } label: {
                    Text("加入採買清單")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isInputValid ? Color.blue : Color.gray)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .disabled(!isInputValid)
            }
            .onAppear {
                inputAmountString = ingredient.quantity >= 1 ? ingredient.quantity.formatted() : "1"
            }
        }
    }
    
    private var isInputValid: Bool {
        guard let amount = Double(inputAmountString), amount > 0 else { return false }
        return true
    }
    
    private func executeReplenish() {
        guard let finalAmount = Double(inputAmountString) else { return }
        
        let newItem = ShoppingItem(
            name: ingredient.name,
            category: ingredient.category,
            targetExpiryDate: targetExpiryDate,
            quantity: finalAmount,
            unit: ingredient.unit,
            isStaple: ingredient.isStaple
        )
        
        withAnimation {
            modelContext.insert(newItem)
        }
        
        onComplete("\(ingredient.name) 已加入清單！")
        dismiss()
    }
}

// MARK: - 🎚️ 消耗抽屜
struct DeductBottomSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var ingredient: Ingredient
    
    var onComplete: ((String?) -> Void)? = nil // 💡 新增：回傳自動補貨訊息的閉包
    
    @State private var inputAmountString: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray4))
                        .frame(width: 40, height: 5)
                        .padding(.top, 10)
                    
                    Text("取出食材庫存")
                        .font(.headline)
                    Text("當前剩餘庫存: \(ingredient.quantity.formatted()) \(ingredient.unit)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        TextField("0", text: $inputAmountString)
                            .keyboardType(.decimalPad)
                            .focused($isTextFieldFocused)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 8)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(isTextFieldFocused ? 0.5 : 0), lineWidth: 2)
                            )
                        
                        Text(ingredient.unit)
                            .font(.title2.bold())
                            .foregroundColor(.secondary)
                            .padding(.trailing, 10)
                    }
                    .padding(.horizontal, 40)
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        inputAmountString = ingredient.quantity.formatted()
                    } label: {
                        Label("全部取出 (一鍵全填)", systemImage: "bolt.fill")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
                
                Button {
                    executeDeduction()
                } label: {
                    Text("確認扣除")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isInputValid ? Color.blue : Color.gray)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .disabled(!isInputValid)
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
    
    private var isInputValid: Bool {
        guard let amount = Double(inputAmountString), amount > 0, amount <= ingredient.quantity else {
            return false
        }
        return true
    }
    
    private func executeDeduction() {
        guard let deductAmount = Double(inputAmountString) else { return }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        var autoReplenishMsg: String? = nil
        
        withAnimation(.spring) {
            ingredient.quantity -= deductAmount
            if ingredient.quantity <= 0 {
                
                // 💡 2. 自動循環補貨引擎：如果是常備食材，用光時立刻新建一個 ShoppingItem
                if ingredient.isStaple {
                    let autoShoppingItem = ShoppingItem(
                        name: ingredient.name,
                        category: ingredient.category,
                        targetExpiryDate: Date().addingTimeInterval(86400 * 7), // 預設一週後
                        quantity: 1.0, // 預設帶入 1
                        unit: ingredient.unit,
                        isStaple: true
                    )
                    modelContext.insert(autoShoppingItem)
                    autoReplenishMsg = "🔄 \(ingredient.name) 已用盡，自動加入採買清單！"
                }
                
                modelContext.delete(ingredient)
            }
            try? modelContext.save()
        }
        
        onComplete?(autoReplenishMsg)
        dismiss()
    }
}
