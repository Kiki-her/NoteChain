# NoteChain — Gemini CLI コンテキストファイル
# このファイルは CLAUDE.md と同期してください（内容は CLAUDE.md が正とする）
# 最終更新: 2026-04-01 | 同期元: CLAUDE.md v1.0

**バージョン:** 1.0 | **Swift:** 6.0 | **最低iOS:** 17.0 | **推奨iOS:** 26+

---

## プロジェクト概要

NoteChain はプライバシーファーストの AI 搭載ボイスメモ iOS アプリです。
音声をリアルタイムで文字起こしし、NaturalLanguage フレームワークが自動でキーワードを
抽出・タグ付けします。すべての処理はオンデバイスで完結し、クラウドバックエンドは不要です。

- **ターゲット**: iOS 17.0 以上（iOS 26+ 推奨）
- **言語サポート**: 英語 / 日本語 / スペイン語
- **マネタイズ**: StoreKit 2 サブスクリプション（月額 $3.99 / 年額 $29.99、14日無料トライアル）
- **参照ドキュメント**: `docs/PRD.md`, `docs/ARCHITECTURE.md`

---

## 技術スタック

| レイヤー          | 技術                                   |
|------------------|----------------------------------------|
| UI               | SwiftUI 100% 宣言的                    |
| 状態管理         | @Observable + MVVM (@MainActor)        |
| ナビゲーション    | NavigationStack + Router (enum ベース) |
| データ永続化     | SwiftData (iOS 17+)                    |
| 音声認識（主）    | SpeechAnalyzer (iOS 26+)              |
| 音声認識（FB）    | SFSpeechRecognizer (iOS 17-25)        |
| キーワード抽出    | NaturalLanguage (NLTagger) MVP        |
| 課金             | StoreKit 2                             |
| テスト           | Swift Testing (@Test / #expect)        |

---

## ディレクトリ構造

```
NoteChain/
├── App/                   # @main エントリポイント・AppState・ContentView
│   ├── NoteChainApp.swift  # ModelContainer 初期化・Environment 注入
│   ├── ContentView.swift   # TabView ルート + Router 統合
│   └── AppState.swift      # @Observable グローバル状態
│
├── Features/              # Vertical Slice（各機能が自己完結）
│   ├── Recording/          # 音声録音 & リアルタイム文字起こし
│   ├── Keywords/           # NLTagger キーワード抽出
│   ├── NotesList/          # ノート一覧・検索・詳細
│   ├── Settings/           # 設定 & 多言語対応
│   ├── Subscription/       # StoreKit 2 サブスクリプション管理
│   └── Onboarding/         # 初回起動フロー（3ステップ）
│
└── Shared/                # 全 Feature が共有する層（Features → Shared のみ）
    ├── Models/             # Note @Model, AppError
    ├── Navigation/         # Router (@Observable), Route enum, AppTab
    ├── Services/           # SpeechRecognitionServiceProtocol + 2実装 + Factory
    ├── Extensions/         # Date+Formatting, String+Localized
    └── Components/         # EmptyStateView, LoadingOverlay, PermissionDeniedView

NoteChainTests/            # Swift Testing テストスイート（Features ミラー構造）
docs/                      # PRD.md, ARCHITECTURE.md, specs/, tasks/
.claude/                   # Claude Code ルール・スキル・コマンド
```

---

## ビルドコマンド（xcodebuild）

```bash
# デバッグビルド
xcodebuild \
  -scheme NoteChain \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -configuration Debug \
  build

# テスト実行
xcodebuild \
  -scheme NoteChain \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -configuration Debug \
  -enableCodeCoverage YES \
  test

# リリースアーカイブ（Fastlane 経由が推奨）
xcodebuild \
  -scheme NoteChain \
  -configuration Release \
  -archivePath build/NoteChain.xcarchive \
  archive
```

---

## 開発ワークフロー

```
Plan → Spec → Implement → Test → Review
```

1. **Plan**: `docs/PRD.md` で要件確認
2. **Spec**: 対象 Feature の `docs/specs/<feature>.md` を確認・生成
3. **Implement**: `docs/ARCHITECTURE.md` の該当モジュール設計に従って実装
4. **Test**: `NoteChainTests/` に Swift Testing テストを作成・実行
5. **Review**: 下記「絶対遵守ルール」と `.claude/rules/` で自己レビュー

---

## 絶対遵守ルール（ALWAYS / NEVER）

### アーキテクチャ

- **NEVER**: `@ObservedObject` / `@Published` / `ObservableObject` を使う → `@Observable` を使う
- **ALWAYS**: ViewModel は `@MainActor @Observable final class` にする
- **NEVER**: `Shared/` レイヤーから `Features/` レイヤーへ依存する（方向: Features → Shared のみ）
- **ALWAYS**: Vertical Slice を遵守する。機能追加は必ず `Features/<Feature>/` 内に閉じる

### 非同期・並行処理

- **NEVER**: `DispatchQueue.global()` / `DispatchQueue.main.async` / Combine を使う
- **ALWAYS**: 非同期処理は `async/await` + `Task` のみ
- **ALWAYS**: `Task {}` を生成したら `deinit` / `.onDisappear` で `task?.cancel()` を呼ぶ
- **NEVER**: `nonisolated(unsafe)` を使用する（Swift 6 では危険）

### SwiftData

- **CRITICAL**: `@Query` マクロは使用禁止 → `ModelContext.fetch(FetchDescriptor<T>())` を使う
- **ALWAYS**: `modelContext.save()` は `try/catch` で囲み `AppError.swiftDataSaveFailed` にラップ

### セキュリティ・プライバシー

- **CRITICAL**: `SFSpeechAudioBufferRecognitionRequest` では必ず `requiresOnDeviceRecognition = true`
- **NEVER**: 音声データ・文字起こしテキストをネットワーク経由で送信する
- **NEVER**: 本番ビルドで `print()` に個人情報を出力する（`#if DEBUG` で囲む）

### ローカライズ

- **ALWAYS**: UI 文字列は `Localizable.xcstrings` のキーを使う（ハードコード禁止）

### StoreKit 2

- **CRITICAL**: `VerificationResult` は必ず `.payloadValue` で署名検証する
- **CRITICAL**: 購入完了後は必ず `await transaction.finish()` を呼ぶ
- **CRITICAL**: ペイウォール画面には必ず閉じるボタン（dismiss）を設置する

### テスト

- **CRITICAL**: `XCTestCase` は使用禁止 → `import Testing` + `@Test` / `#expect`
- **ALWAYS**: SwiftData テストは `ModelConfiguration(isStoredInMemoryOnly: true)`

---

## 詳細ルール参照先

| ファイル | 内容 |
|---------|------|
| `.claude/rules/general.md` | アーキテクチャ・コーディング全般 |
| `.claude/rules/security.md` | セキュリティ・プライバシー |
| `.claude/rules/swift-style.md` | Swift 6 / Concurrency |
| `.claude/rules/swiftui.md` | SwiftUI パターン |
| `.claude/rules/swiftdata.md` | SwiftData / @Model |
| `.claude/rules/testing.md` | Swift Testing |
| `.claude/rules/subscription.md` | StoreKit 2 |
