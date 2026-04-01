# Settings モジュール

## 概要
ユーザー設定（録音言語・UI言語）の管理と多言語対応を担当するモジュール。

## ファイル構成

```
NoteChain/Features/Settings/
├── README.md              # このファイル
├── SettingsView.swift     # 設定画面 View
├── SettingsViewModel.swift # 設定状態管理 ViewModel
└── LanguagePickerView.swift # 言語選択 View（push ナビゲーション）
```

## 責務

- `@AppStorage` を介した設定の永続化
- 録音言語（en-US / ja-JP / es-ES / auto）の管理
- UI 表示言語（system / en / ja / es）の管理
- `speechLocale` 計算プロパティによる SpeechRecognitionService への言語提供
- 週次ノートカウントのリセット管理

## 依存関係

- **依存先**: Shared/Models（設定値の型）
- **依存元**: Recording（speechLocale 利用）、App（hasCompletedOnboarding 確認）

## 受け入れ基準（Given-When-Then）

- **Given** 設定画面が開かれている **When** 録音言語を日本語に変更する **Then** 録音 ViewModel の speechLocale が ja-JP になる
- **Given** UI 言語が日本語に設定されている **When** アプリを再起動する **Then** 全画面が日本語で表示される
- **Given** 無料プランで週3件ノートを作成した **When** 4件目を録音しようとする **Then** ペイウォールが表示される
