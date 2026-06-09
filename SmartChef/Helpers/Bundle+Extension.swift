//
//  Constants.swift
//  SmartChef
//
//  Created by patrick on 2026/6/2.
//

import Foundation

extension Bundle {
    var geminiAPIKey: String {
        // 從 Info.plist 中讀取安全變數
        guard let key = object(forInfoDictionaryKey: "GeminiAPIKey") as? String, !key.isEmpty else {
            fatalError("🚨 錯誤：找不到 Gemini API Key。請確保已在 Development.xcconfig 中設定並配置於 Info.plist。")
        }
        return key
    }
    var unsplashAccessKey: String {
        guard let key = object(forInfoDictionaryKey: "UnsplashAccessKey") as? String, !key.isEmpty else {
            fatalError("🚨 錯誤：找不到 Unsplash Access Key。")
        }
        return key
    }
}
