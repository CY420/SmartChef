//
//  AddIngredientView.swift
//  SmartChef
//
//  Created by patrick on 2026/6/6.
//

import SwiftUI
import SwiftData

struct AddIngredientView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var category: String = "蔬菜"
    @State private var quantityString: String = "1"
    
    // 💡 魔法自訂單位核心狀態
    @State private var unit: String = "個"
    @State private var isEnteringCustomUnit: Bool = false
    @FocusState private var isCustomUnitFocused: Bool
    
    @State private var storageLocation: String = "冷藏"
    @State private var expiryDate: Date = Date().addingTimeInterval(86400 * 7)
    @State private var isStaple: Bool = false
    @State private var notes: String = ""
    
    let categories = ["蔬菜", "水果", "肉類", "海鮮", "蛋奶", "調味料", "飲品", "甜點", "乾貨", "其他"]
    let defaultUnits = ["個", "顆", "克(g)", "台斤", "把", "盒", "瓶", "條", "包", "ml", "L"]
    let locations = ["冷藏", "冷凍", "乾貨"]
    
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
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("分類").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                                    Menu {
                                        ForEach(categories, id: \.self) { cat in
                                            Button(cat) {
                                                category = cat
                                                autoAssignLocation(for: cat) // 智慧預判儲存位置
                                            }
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
                                        Menu {
                                            ForEach(defaultUnits, id: \.self) { u in
                                                Button(u) { unit = u }
                                            }
                                            Divider()
                                            Button("自訂單位...") {
                                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                    unit = ""
                                                    isEnteringCustomUnit = true
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                                    isCustomUnitFocused = true
                                                }
                                            }
                                        } label: {
                                            HStack {
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
                        
                        // ⚖️ 區塊二：數量、位置與效期
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("入庫數量").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                                    TextField("1", text: $quantityString)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .multilineTextAlignment(.center)
                                        .padding(.vertical, 8)
                                        .background(Color(.secondarySystemGroupedBackground))
                                        .cornerRadius(12)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("儲存位置").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                                    Menu {
                                        ForEach(locations, id: \.self) { loc in
                                            Button(loc) { storageLocation = loc }
                                        }
                                    } label: {
                                        HStack {
                                            Text(storageLocation)
                                                .font(.headline)
                                            Spacer()
                                            Image(systemName: "chevron.up.chevron.down")
                                        }
                                        .foregroundColor(locationColor(for: storageLocation))
                                        .padding(.vertical, 12)
                                        .padding(.horizontal)
                                        .background(Color(.secondarySystemGroupedBackground))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                DatePicker("有效期限", selection: $expiryDate, displayedComponents: .date)
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
            .navigationTitle("新增庫存食材")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("入庫") { saveIngredient() }
                        .font(.headline)
                        .disabled(!isFormValid)
                }
            }
            // 💡 監聽鍵盤收起
            .onChange(of: isCustomUnitFocused) { oldValue, newValue in
                if oldValue && !newValue {
                    completeCustomUnitInput()
                }
            }
        }
    }
    
    private func completeCustomUnitInput() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isEnteringCustomUnit = false
            if unit.trimmingCharacters(in: .whitespaces).isEmpty {
                unit = "個"
            }
        }
    }
    
    // UI 輔助邏輯
    private func locationColor(for loc: String) -> Color {
        switch loc {
        case "冷凍": return .blue
        case "冷藏": return .teal
        default: return .orange
        }
    }
    
    private func autoAssignLocation(for cat: String) {
        switch cat {
        case "肉類", "海鮮": storageLocation = "冷凍"
        case "蔬菜", "水果", "蛋奶", "飲品", "甜點": storageLocation = "冷藏"
        default: storageLocation = "乾貨"
        }
    }
    
    private func saveIngredient() {
        guard let quantity = Double(quantityString) else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        let newIngredient = Ingredient(
            name: name,
            category: category,
            expiryDate: expiryDate,
            quantity: quantity,
            unit: unit,
            storageLocation: storageLocation,
            isStaple: isStaple,
            notes: notes
        )
        
        modelContext.insert(newIngredient)
        try? modelContext.save()
        dismiss()
    }
}
