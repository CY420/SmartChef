//
//  ShoppingListView.swift
//  SmartChef
//
//  Created by 114-2Student03 on 2026/6/2.
//

import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \ShoppingItem.addedDate, order: .reverse) private var shoppingItems: [ShoppingItem]
    
    @State private var showingAddSheet = false
    @State private var showingAlert = false
    @State private var alertType: AlertType = .clearAll
    
    @State private var itemToEdit: ShoppingItem? = nil
    
    enum AlertType {
        case clearAll
        case syncCompleted
    }
    
    // MARK: - 📍 超市走道動線分區
    var produceItems: [ShoppingItem] {
        shoppingItems.filter { !$0.isPurchased && ["蔬菜", "水果"].contains($0.category) }
    }
    
    var proteinItems: [ShoppingItem] {
        shoppingItems.filter { !$0.isPurchased && ["肉類", "海鮮", "蛋奶"].contains($0.category) }
    }
    
    var pantryItems: [ShoppingItem] {
        shoppingItems.filter { !$0.isPurchased && !["蔬菜", "水果", "肉類", "海鮮", "蛋奶"].contains($0.category) }
    }
    
    var purchasedItems: [ShoppingItem] {
        shoppingItems.filter { $0.isPurchased }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()
                
                VStack(spacing: 0) {
                    CustomHeaderView(
                        title: "採買清單",
                        subtitle: "SHOPPING LIST",
                        leadingContent: {
                            if !shoppingItems.isEmpty {
                                Menu {
                                    Button(role: .destructive) {
                                        alertType = .clearAll
                                        showingAlert = true
                                    } label: {
                                        Label("化為煙霧 (一鍵清空)", systemImage: "smoke")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.title3.weight(.bold))
                                        .foregroundColor(.secondary)
                                }
                            } else { Spacer() }
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
                    
                    if shoppingItems.isEmpty {
                        ContentUnavailableView(
                            "購物清單空空的",
                            systemImage: "cart",
                            description: Text("從我的冰箱右滑加入，或點擊右上角手動新增待買食材。")
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 24) {
                                
                                if !produceItems.isEmpty {
                                    AisleSection(title: "生鮮蔬果區", icon: "leaf.fill", color: .green, items: produceItems) { item in
                                        itemToEdit = item
                                    }
                                }
                                if !proteinItems.isEmpty {
                                    AisleSection(title: "肉類海鮮區", icon: "fish.fill", color: .red, items: proteinItems) { item in
                                        itemToEdit = item
                                    }
                                }
                                if !pantryItems.isEmpty {
                                    AisleSection(title: "調味乾貨區", icon: "shippingbox.fill", color: .orange, items: pantryItems) { item in
                                        itemToEdit = item
                                    }
                                }
                                
                                if !purchasedItems.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                            Text("已放入購物車")
                                                .font(.title3.bold())
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            
                                            Button {
                                                alertType = .syncCompleted
                                                showingAlert = true
                                            } label: {
                                                Text("同步入冰箱")
                                                    .font(.caption.bold())
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(Color.blue.opacity(0.15))
                                                    .foregroundColor(.blue)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        .padding(.top, 16)
                                        
                                        LazyVStack(spacing: 12) {
                                            ForEach(purchasedItems) { item in
                                                ShoppingItemCard(item: item) {
                                                    itemToEdit = item
                                                }
                                                .transition(.asymmetric(
                                                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                                                    removal: .scale(scale: 0.1).combined(with: .opacity)
                                                ))
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddSheet) {
                AddShoppingItemView()
            }
            .sheet(item: $itemToEdit) { item in
                ShoppingItemEditorSheet(item: item)
                    .presentationDetents([.fraction(0.85), .large])
                    .presentationDragIndicator(.visible)
            }
            .alert(isPresented: $showingAlert) {
                switch alertType {
                case .clearAll:
                    return Alert(
                        title: Text("確定要清空整份清單？"),
                        message: Text("這將刪除所有待買與已購買項目。"),
                        primaryButton: .destructive(Text("清空")) { clearAllItems() },
                        secondaryButton: .cancel(Text("取消"))
                    )
                case .syncCompleted:
                    return Alert(
                        title: Text("結帳完畢！準備入庫？"),
                        message: Text("這會將「已放入購物車」的食材正式寫入冰箱，並從採買清單移除。"),
                        primaryButton: .default(Text("確定入庫")) { syncCompletedItems() },
                        secondaryButton: .cancel(Text("取消"))
                    )
                }
            }
        }
    }
    
    private func clearAllItems() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            for item in shoppingItems {
                modelContext.delete(item)
            }
            try? modelContext.save()
        }
    }
    
    private func syncCompletedItems() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            for item in purchasedItems {
                let smartLocation: String
                switch item.category {
                case "肉類", "海鮮": smartLocation = "冷凍"
                case "蔬菜", "水果", "蛋奶": smartLocation = "冷藏"
                default: smartLocation = "乾貨"
                }
                
                let newIngredient = Ingredient(
                    name: item.name,
                    category: item.category,
                    expiryDate: item.targetExpiryDate,
                    quantity: item.quantity,
                    unit: item.unit,
                    storageLocation: smartLocation,
                    isStaple: item.isStaple,
                    notes: item.notes // 確保備註完美傳遞
                )
                
                modelContext.insert(newIngredient)
                modelContext.delete(item)
            }
            try? modelContext.save()
        }
    }
}

// MARK: - 🛒 走道區塊元件
struct AisleSection: View {
    let title: String
    let icon: String
    let color: Color
    let items: [ShoppingItem]
    var onEditItem: (ShoppingItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(items) { item in
                    ShoppingItemCard(item: item) {
                        onEditItem(item)
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .scale(scale: 0.1).combined(with: .opacity)
                    ))
                }
            }
        }
    }
}

// MARK: - 📇 購物卡片
struct ShoppingItemCard: View {
    @Bindable var item: ShoppingItem
    var onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                UIImpactFeedbackGenerator(style: item.isPurchased ? .light : .medium).impactOccurred()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    item.isPurchased.toggle()
                }
            } label: {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundColor(item.isPurchased ? .blue : .gray.opacity(0.5))
                    .scaleEffect(item.isPurchased ? 1.1 : 1.0)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Button(action: onEdit) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.name)
                            .font(.headline)
                            .foregroundColor(item.isPurchased ? .secondary : .primary)
                            .strikethrough(item.isPurchased, color: .secondary)
                        
                        HStack(spacing: 6) {
                            if item.isStaple {
                                Text("常備")
                                    .font(.caption2.weight(.heavy))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue)
                                    .clipShape(Capsule())
                            }
                            
                            Text(item.category)
                                .font(.caption2.bold())
                                .foregroundColor(item.isPurchased ? .secondary : .primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(item.isPurchased ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                            
                            Text("效期: \(item.targetExpiryDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(item.quantity.formatted())
                            .font(.title3.bold())
                            .fontDesign(.rounded)
                            .foregroundColor(item.isPurchased ? .secondary : .primary)
                        Text(item.unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(item.isPurchased ? Color(.tertiarySystemGroupedBackground) : Color(.secondarySystemGroupedBackground))
        )
        .scaleEffect(item.isPurchased ? 0.96 : 1.0)
        .opacity(item.isPurchased ? 0.6 : 1.0)
        .shadow(color: .black.opacity(item.isPurchased ? 0 : 0.04), radius: 8, y: 4)
    }
}

// MARK: - 📝 購物項目編輯器 (整合魔法自訂單位)
struct ShoppingItemEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: ShoppingItem
    
    let categories = ["蔬菜", "水果", "肉類", "海鮮", "蛋奶", "調味料", "飲品", "甜點", "乾貨", "其他"]
    let defaultUnits = ["個", "顆", "克(g)", "台斤", "把", "盒", "瓶", "條", "包", "ml", "L"]
    
    @State private var inputAmountString: String = ""
    
    // 💡 魔法自訂單位核心狀態
    @State private var isEnteringCustomUnit: Bool = false
    @FocusState private var isCustomUnitFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 區塊一：基本資訊
                        VStack(spacing: 16) {
                            HStack {
                                Text("食材名稱")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            TextField("輸入名稱", text: $item.name)
                                .font(.title3.bold())
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                                
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("分類").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                                    Menu {
                                        ForEach(categories, id: \.self) { cat in
                                            Button(cat) { item.category = cat }
                                        }
                                    } label: {
                                        HStack {
                                            Text(item.category)
                                            Spacer()
                                            Image(systemName: "chevron.up.chevron.down")
                                        }
                                        .foregroundColor(.primary)
                                        .padding()
                                        .background(Color(.secondarySystemGroupedBackground))
                                        .cornerRadius(12)
                                    }
                                }
                                
                                // 💡 編輯模式下的「魔法自訂單位」
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("單位").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                                    
                                    if isEnteringCustomUnit {
                                        TextField("輸入新單位", text: $item.unit)
                                            .focused($isCustomUnitFocused)
                                            .padding()
                                            .background(Color(.secondarySystemGroupedBackground))
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                                            )
                                            .onSubmit { completeCustomUnitInput() }
                                    } else {
                                        Menu {
                                            ForEach(defaultUnits, id: \.self) { u in
                                                Button(u) { item.unit = u }
                                            }
                                            Divider()
                                            Button("自訂單位...") {
                                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                    item.unit = "" // 清空準備輸入
                                                    isEnteringCustomUnit = true
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                                    isCustomUnitFocused = true
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                Text(item.unit.isEmpty ? "自訂單位" : item.unit)
                                                    .foregroundColor(item.unit.isEmpty ? .secondary : .primary)
                                                Spacer()
                                                Image(systemName: "chevron.up.chevron.down")
                                            }
                                            .foregroundColor(.primary)
                                            .padding()
                                            .background(Color(.secondarySystemGroupedBackground))
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.tertiarySystemGroupedBackground)))
                        
                        // 區塊二：數量與效期
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("採買數量").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                                TextField("1", text: $inputAmountString)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 8)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(12)
                                    .onChange(of: inputAmountString) { oldValue, newValue in
                                        if let val = Double(newValue) { item.quantity = val }
                                    }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                DatePicker("預期有效期限", selection: $item.targetExpiryDate, displayedComponents: .date)
                                    .font(.subheadline.weight(.medium))
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.tertiarySystemGroupedBackground)))
                        
                        // 區塊三：常備設定與備註
                        VStack(spacing: 16) {
                            Toggle(isOn: $item.isStaple) {
                                VStack(alignment: .leading) {
                                    Text("📌 設為常備食材")
                                        .font(.headline)
                                    Text("入庫後用盡將自動回到採買清單")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tint(.blue)
                            
                            Divider().padding(.vertical, 4)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("隱藏備註 (AI 分析用)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                }
                                
                                TextField("例如：低脂、微辣、有機...", text: $item.notes)
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.tertiarySystemGroupedBackground)))
                    }
                    .padding(16)
                }
            }
            .navigationTitle("編輯採買項目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        try? item.modelContext?.save()
                        dismiss()
                    }
                    .font(.headline)
                }
            }
            .onAppear {
                inputAmountString = item.quantity.formatted()
            }
            // 💡 監聽鍵盤收起
            .onChange(of: isCustomUnitFocused) { oldValue, newValue in
                if oldValue && !newValue {
                    completeCustomUnitInput()
                }
            }
        }
    }
    
    // 💡 完成輸入，平滑縮回 Menu 狀態
    private func completeCustomUnitInput() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isEnteringCustomUnit = false
            if item.unit.trimmingCharacters(in: .whitespaces).isEmpty {
                item.unit = "個" // 防呆：如果沒輸入就點掉，恢復預設
            }
        }
    }
}
