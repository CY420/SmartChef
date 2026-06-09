# 智選主廚 (SmartChef) 🍳✨

**SmartChef** 是一款結合「精品級玻璃擬物化 (Glassmorphism) 設計」與「Edge + Cloud 混合 AI 引擎」的現代化 iOS 智慧廚房管家。它不僅僅是一個冰箱管理工具，更是一個能自動運轉的「常備食材永動機」，並能隨時將剩餘庫存化為星級私房菜譜。

---

## ✨ 核心亮點 (Core Features)

### 🧊 智慧視覺儲存艙 (Inventory View)
* **動態儀表板與呼吸燈警示**：首創三階視覺防線，利用 iOS 17 `.phaseAnimator` 漸層呼吸燈，直覺提示即將過期食材。
* **極速操作抽屜**：內嵌 `@FocusState` 自動鍵盤與「⚡ 一鍵全填」閃電快捷鈕的半版抽屜，消耗與補貨只需彈指之間。
* **常備食材永動機 (Auto-Loop Replenishment)**：殺手級功能。當標記為「📌 常備」的食材庫存歸零時，系統會從冰箱自動將其移轉至「採買清單」，購買後一鍵入庫又會完美繼承常備屬性，形成生生不息的無限循環。

### 🛒 超市情境導覽器 (Shopping List)
* **走道動線分區**：系統依食材特性自動分組為「生鮮蔬果」、「肉類海鮮」與「調味乾貨」，完美貼合真實逛超市的動線。
* **物質吸入與解體動畫**：購物打勾時的流暢縮小滑降歸檔，以及「同步入冰箱」時化為煙霧的轉場動畫，提供極致的物理反饋 (Haptic Feedback)。
* **無縫自訂單位魔法**：精緻的下拉選單結合動畫過渡，點擊「自訂單位」後優雅變身為輸入框，兼顧極簡美學與實用性。

### 👨‍🍳 星級私房菜 (AI Chef Platform)
* **邊緣語意萃取 (On-Device NLP)**：利用 Apple 原生 `NaturalLanguage` 框架，離線掃描食材隱藏備註（如：低脂、微辣），自動化為「✨ 魔法星光標籤」。
* **雙引擎多模態生成**：結合 Google Gemini 3.1 Flash API 生成結構化食譜，並聯動 Unsplash API 動態獲取高畫質情境圖。
* **雜誌風雙層英雄卡**：客製化 Markdown 解析引擎，數字放大、襯線體排版，提供如翻閱頂級美食雜誌般的沉浸式閱讀體驗。

---

## 🛠 技術棧與架構 (Tech Stack & Architecture)

### Frontend & UI/UX
* **Framework**: SwiftUI (MVVM Architecture, `@Observable` state management)
* **Design System**: 全域自訂 `AmbientBackground` (網格光暈 Mesh Gradient)、`CustomHeaderView`、Glassmorphism
* **Layout Engine**: Custom `Layout` protocol (Tag Cloud 泡泡標籤池)

### Data & Backend
* **Local Storage**: SwiftData (Multi-model sync and persistence)
* **Cloud AI**: Google Gemini 3.1 Flash RESTful API (JSON mode)
* **Edge ML**: Apple `NLTagger` (Natural Language Processing)
* **Image Handling**: [Kingfisher](https://github.com/onevcat/Kingfisher) (Asynchronous downloading and caching)

---
