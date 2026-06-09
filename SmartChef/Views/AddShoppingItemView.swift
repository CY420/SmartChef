//
//  AddShoppingItemView.swift
//  SmartChef
//
//  Created by patrick on 2026/6/5.
//

import SwiftUI
import SwiftData

struct AddShoppingItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var category: String = "蔬菜"
    @State private var quantityString: String = "1"
    
    // 💡 魔法自訂單位核心狀態
    @State private var unit: String = "個"
    @State private var isEnteringCustomUnit: Bool = false
    @FocusState private var isCustomUnitFocused: Bool
    
    @State private var targetExpiryDate: Date = Date().addingTimeInterval(86400 * 7)
    @State private var isStaple: Bool = false
    @State private var notes: String = ""
    
    let categories = ["蔬菜", "水果", "肉類", "海鮮", "蛋奶", "調味料", "飲品", "甜點", "乾貨", "其他"]
    let defaultUnits = ["個", "顆", "克(g)", "台斤", "把", "盒", "瓶", "條", "包", "ml", "L"]
    
    private var isFormValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard let qty = Double(quantityString), qty > 0 else { return false }
        return true
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 📦 區塊一：基本資訊
                        VStack(spacing: 16) {
                            HStack {
                                Text("食材名稱").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                                Spacer()
                            }
                            TextField("輸入名稱 (必填)", text: $name)
                                .font(.title3.bold())
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            
                            HStack(spacing: 16) {
                                // 分類選單
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("分類").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                                    Menu {
                                        ForEach(categories, id: \.self) { cat in
                                            Button(cat) { category = cat }
                                        }
                                    } label: {
                                        HStack {
                                            Text(category)
                                            Spacer()
                                            Image(systemName: "chevron.up.chevron.down")
                                        }
                                        .foregroundColor(.primary)
                                        .padding()
                                        .background(Color(.secondarySystemGroupedBackground))
                                        .cornerRadius(12)
                                    }
                                }
                                
                                // 💡 魔法自訂單位區塊
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("單位").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                                    
                                    if isEnteringCustomUnit {
                                        // 展開成輸入框
                                        TextField("輸入新單位", text: $unit)
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
                                        // 原本的優雅 Menu
                                        Menu {
                                            ForEach(defaultUnits, id: \.self) { u in
                                                Button(u) { unit = u }
                                            }
                                            Divider()
                                            Button("自訂單位...") {
                                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                    unit = "" // 清空準備輸入
                                                    isEnteringCustomUnit = true
                                                }
                                                // 確保視圖轉換完成後立即喚起鍵盤
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                                    isCustomUnitFocused = true
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                // 若非預設單位，也會完美顯示在此
                                                Text(unit.isEmpty ? "自訂單位" : unit)
                                                    .foregroundColor(unit.isEmpty ? .secondary : .primary)
                                                Spacer()
                                                Image(systemName: "chevron.up.chevron.down")
                                            }
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
                        
                        // ⚖️ 區塊二：數量與效期
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("採買數量").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                                TextField("1", text: $quantityString)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 8)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(12)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                DatePicker("預期有效期限", selection: $targetExpiryDate, displayedComponents: .date)
                                    .font(.subheadline.weight(.medium))
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.tertiarySystemGroupedBackground)))
                        
                        // ✨ 區塊三：進階設定
                        VStack(spacing: 16) {
                            Toggle(isOn: $isStaple) {
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
                                
                                TextField("例如：低脂、微辣、有機...", text: $notes)
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
            .navigationTitle("新增採買項目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("新增") { saveItem() }
                        .font(.headline)
                        .disabled(!isFormValid)
                }
            }
            // 💡 監聽鍵盤收起 (點擊空白處時自動確認單位)
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
            if unit.trimmingCharacters(in: .whitespaces).isEmpty {
                unit = "個" // 防呆：如果沒輸入就點掉，恢復預設
            }
        }
    }
    
    private func saveItem() {
        guard let quantity = Double(quantityString) else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        let newItem = ShoppingItem(
            name: name,
            category: category,
            targetExpiryDate: targetExpiryDate,
            quantity: quantity,
            unit: unit,
            isStaple: isStaple,
            notes: notes
        )
        
        modelContext.insert(newItem)
        try? modelContext.save()
        dismiss()
    }
}
