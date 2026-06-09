//
//  SmartChefViewModel.swift
//  SmartChef
//
//  Created by 114-2Student03 on 2026/6/2.
//

import Foundation
import NaturalLanguage
import Observation

@Observable
final class SmartChefViewModel {
    
    // MARK: - AI 食譜生成狀態管理
    var isGeneratingRecipe: Bool = false
    var generatedRecipe: String? = nil
    var recipeImageURL: URL? = nil
    
    // 💡 演算法權重：依據全新九大分類的腐壞速度與冷藏保存需求，微調啟發式權重比例
    private let categoryWeights: [String: Double] = [
        "肉類": 1.5,
        "海鮮": 1.5,
        "蔬菜": 1.3,
        "水果": 1.2,
        "蛋奶": 1.1,
        "甜點": 1.0,
        "飲品": 0.7,
        "調味料": 0.5,
        "其他": 0.5
    ]
    
    // MARK: - 🧠 1. 啟發式急迫性演算法 (Urgency Engine)
    
    /// 計算單一食材的急迫性分數
    func calculateUrgencyScore(for ingredient: Ingredient) -> Double {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfExpiry = calendar.startOfDay(for: ingredient.expiryDate)
        
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfExpiry)
        let daysToExpiration = components.day ?? 0
        
        let weight = categoryWeights[ingredient.category] ?? 0.5
        
        // 若已經過期，賦予極高分數強制置頂，數量越多越急迫
        if daysToExpiration < 0 {
            return 1000.0 + ingredient.quantity
        }
        
        // 💡 演算法重構：移除舊版剩餘百分比，改以效期天數倒數作為核心分母
        // 核心公式： ( 1.0 / (距離天數 + 1) ) * 分類權重
        let score = (1.0 / Double(daysToExpiration + 1)) * weight
        return score
    }
    
    /// 傳入食材陣列，回傳依急迫性分數遞減排序後的陣列
    func sortIngredientsByUrgency(_ ingredients: [Ingredient]) -> [Ingredient] {
        return ingredients.sorted {
            calculateUrgencyScore(for: $0) > calculateUrgencyScore(for: $1)
        }
    }
    
    // MARK: - 🗣️ 2. 自然語言處理 (NLP Parser)
    
    /// 使用 Apple NLTagger 萃取備註中的關鍵字
    func extractKeywords(from text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        var keywords: [String] = []
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            if let tag = tag, (tag == .noun || tag == .adjective) {
                keywords.append(String(text[tokenRange]))
            }
            return true
        }
        return keywords
    }
    
    // MARK: - 🖼️ 3. 真實串接 Unsplash API
    
    /// 傳入英文關鍵字，向 Unsplash 請求橫向美食美照
    private func fetchUnsplashImage(keyword: String) async -> URL? {
        let accessKey = Bundle.main.unsplashAccessKey
        
        // 安全處理網址字元編碼
        let query = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "food"
        let urlString = "https://api.unsplash.com/search/photos?query=\(query)&client_id=\(accessKey)&per_page=1&orientation=landscape"
        
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("v1", forHTTPHeaderField: "Accept-Version")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]],
               let firstPhoto = results.first,
               let urls = firstPhoto["urls"] as? [String: String],
               let regularImageURL = urls["regular"] {
                return URL(string: regularImageURL)
            }
        } catch {
            print("Unsplash API 連線異常: \(error.localizedDescription)")
        }
        return nil
    }
    
    // MARK: - 👨‍🍳 4. 真實連結 Google Gemini API 引擎 (核心優化版)
    
    @MainActor
    func generateRecipe(using selectedIngredients: [Ingredient]) async {
        self.isGeneratingRecipe = true
        self.generatedRecipe = nil
        self.recipeImageURL = nil
        
        // 取得安全金鑰
        let apiKey = Bundle.main.geminiAPIKey
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            self.generatedRecipe = "系統錯誤：無效的 API 網址"
            self.isGeneratingRecipe = false
            return
        }
        
        // 整合食材、數量與單位，建構精準 Prompt 資料流
        let ingredientDetails = selectedIngredients.map { "\($0.name)(\($0.quantity.formatted())\($0.unit))" }.joined(separator: "、")
        let allKeywords = selectedIngredients.flatMap { extractKeywords(from: $0.notes) }
        let uniqueKeywords = Array(Set(allKeywords)).joined(separator: ", ")
        
        // 💡 提示詞擴充：納入全新九大分類的引導語，確保回傳乾淨 JSON
        let prompt = """
        你是一位獲得米其林星級認證的創意主廚。請用以下使用者從冰箱中「指定挑選」的現有食材與數量幫他客製化一道星級料理：[\(ingredientDetails)]。
        
        【食材使用嚴格限制】：
        1. 必須且只能以這些指定食材為主料，數量可在指定範圍內自行調配，不可憑空加入其他「需要額外購買的主菜或蔬菜（如雞肉、牛肉、海鮮、整顆洋蔥等）」。
        2. 為了料理完整性，你可以自由加入廚房基本常備的「調味料與基礎辛香料」（例如：水、鹽、胡椒、醬油、大蒜、食用油）。

        【使用者偏好與 NLP 魔法星光標籤】：
        使用者的偏好備註與離線 NLTagger 萃取的關鍵字包含：[\(uniqueKeywords)]。請務必將這些風格（如：低脂、大辣、有機）完美融入烹飪手法或調味中。
        
        請務必以精準的 JSON 格式回傳，不可夾帶任何 ```json 等 Markdown 標記（直接以花括號開頭與結尾），格式範例如下：
        {
          "recipe": "### ✨ 智選特製：[極具雜誌高級感的創意菜名]\\n\\n#### 🍳 所需食材\\n- 指定食材與比例...\\n- 基礎常備調味...\\n\\n#### 📖 料理步驟\\n1. [步驟標題] 步驟詳細敘述，注意：請確保步驟中有明確的「數字」（例如：3分鐘、2湯匙、180度），以利前端排版引擎將數字放大呈現襯線體質感。\\n2. [步驟標題] ...",
          "english_keyword": "最符合這道菜核心視覺的單一英文名詞（例如: steak, gourmet, pasta, salad, soup，限用單數英文，將直接用於 Unsplash API 圖片搜尋）"
        }
        """
        
        // 傳入 responseMimeType 強制啟動 Google 伺服器的硬性 JSON 模式
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "responseMimeType": "application/json"
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            self.generatedRecipe = "系統錯誤：無法解析請求封包"
            self.isGeneratingRecipe = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 工業級 HTTP 狀態碼攔截過濾機制
            if let httpResponse = response as? HTTPURLResponse {
                print("--- HTTP 狀態碼: \(httpResponse.statusCode) ---")
                
                if httpResponse.statusCode != 200 {
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("Google API 錯誤內容: \(errorString)")
                    }
                    
                    switch httpResponse.statusCode {
                    case 429: self.generatedRecipe = "🍳 呼叫太頻繁囉！請稍等一分鐘再試一次。"
                    case 503: self.generatedRecipe = "⏳ AI 主廚目前忙不過來（伺服器高乘載）！這通常是暫時的，請過幾秒鐘再點一次。"
                    case 404: self.generatedRecipe = "🔍 找不到 AI 模型，請確認模型名稱是否正確。"
                    case 400: self.generatedRecipe = "⚙️ 傳送的資料格式有誤，請確認食材內容後再試一次。"
                    case 403: self.generatedRecipe = "🔑 API Key 驗證失敗，請確認您的憑證權限是否有效。"
                    default:  self.generatedRecipe = "連線失敗：伺服器回應狀態碼 \(httpResponse.statusCode)"
                    }
                    self.isGeneratingRecipe = false
                    return
                }
            }
            
            // 雙重 JSON 解包技術 (Dual-Parsing Pipeline)
            // 階段一：解析 Google API 回傳的外層封包
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let firstPart = parts.first,
               let jsonReplyText = firstPart["text"] as? String {
                
                print("Gemini 回傳的原始巢狀 JSON 字串: \(jsonReplyText)")
                
                // 階段二：將 AI 回傳的字串轉回 Data，解析出內層客製化欄位
                if let nestedData = jsonReplyText.data(using: .utf8),
                   let recipeJSON = try? JSONSerialization.jsonObject(with: nestedData) as? [String: Any] {
                    
                    // 1. 導出食譜本文 (保留 Markdown 結構供 UI 的 LocalizedStringKey 原生渲染)
                    self.generatedRecipe = recipeJSON["recipe"] as? String
                    
                    // 2. 導出 AI 智慧翻譯生成的英文關鍵字
                    let dynamicEnglishKeyword = recipeJSON["english_keyword"] as? String ?? "cooking food"
                    print("Gemini 輸出之動態 Unsplash 關鍵字: \(dynamicEnglishKeyword)")
                    
                    // 3. 發送真實的 Unsplash 橫向圖片搜尋
                    if let fetchedURL = await fetchUnsplashImage(keyword: dynamicEnglishKeyword) {
                        self.recipeImageURL = fetchedURL
                    } else {
                        // 完美備案機制 (Fallback)
                        let category = selectedIngredients.first?.category ?? ""
                        self.recipeImageURL = getFallbackImageURL(for: category)
                    }
                } else {
                    self.generatedRecipe = "內層解析錯誤：AI 回傳的內容不符合標準 JSON 格式"
                }
            } else {
                self.generatedRecipe = "外層解析錯誤：無法讀取 AI 回覆結構"
            }
        } catch {
            self.generatedRecipe = "連線異常：\(error.localizedDescription)"
        }
        
        self.isGeneratingRecipe = false
    }
    
    /// 備用圖片庫安全機制（已全面升級對應全新九大分類）
    private func getFallbackImageURL(for category: String) -> URL {
        let fallbackPhotoID: String
        switch category {
        case "肉類": fallbackPhotoID = "photo-1603048588665-791ca8aea617" // 煎牛排
        case "海鮮": fallbackPhotoID = "photo-1534080564583-6be75777b70a" // 海鮮拼盤
        case "蔬菜": fallbackPhotoID = "photo-1540420773420-3366772f4999" // 鮮蔬沙拉
        case "水果": fallbackPhotoID = "photo-1619546813926-a78fa6372cd2" // 新鮮水果
        case "蛋奶": fallbackPhotoID = "photo-1506084868230-bb9d95c24759" // 烘焙蛋料理
        case "調味料": fallbackPhotoID = "photo-1596040033229-a9821ebd058d" // 廚房香料
        case "飲品": fallbackPhotoID = "photo-1513558161293-cdaf765ed2fd" // 質感飲品
        case "甜點": fallbackPhotoID = "photo-1551024601-bec78aea704b" // 蛋糕精選
        default: fallbackPhotoID = "photo-1504674900247-0877df9cc836"    // 經典料理
        }
        return URL(string: "[https://images.unsplash.com/](https://images.unsplash.com/)\(fallbackPhotoID)?auto=format&fit=crop&w=1000&q=80")!
    }
}
