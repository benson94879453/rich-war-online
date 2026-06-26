# Rich War Online 開發問答筆記

本文件用於記錄開發過程中詢問過的問題與答案簡述，以便隨時查閱。

> Note: entries below include historical prototype context. The current active baseline scene is `res://scenes/StarQGame.tscn`; do not use older `Main.tscn` notes for baseline validation.

---

## 1. 專案現況與規格 (2026-06-19)
* **問題**：解釋一下專案現況。
* **答覆簡述**：
  * **引擎與平台**：使用 Godot 4.6.x stable，目標 Web (最高優先)、Windows、macOS。
  * **核心玩法**：大富翁資產經營 + 「他人回合干預卡/干預窗口」線上多人桌遊。
  * **當前進度**：處於 **P0 技術原型開發前**。主場景 `Main.tscn` 已擺放 40 格棋盤與兩個測試棋子，並有基礎的單人擲骰移動功能。
  * **下階段目標**：完成 **P0.1 本地棋盤原型**，即實作 2 名玩家在單機輪流擲骰移動與回合切換。

## 2. Board 節點的 `origin` 參數作用 (2026-06-20)
* **問題**：Board 的 `origin` 是什麼參數？
* **答覆簡述**：
  * **定義**：為一個 `Vector2` 類型的導出屬性，預設為 `Vector2(0, 0)`。
  * **用途**：代表整個環狀棋盤在局部空間的**左上角起點位置（偏移量）**。
  * **原理**：在 `Board.gd` 計算所有格子座標時，會以 `origin` 作為基正點加上各格子的行列偏移。調整此值可整體平移棋盤在畫面上的顯示位置。
