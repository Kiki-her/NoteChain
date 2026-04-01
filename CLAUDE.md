# NoteChain — AI駆動開発メイン指示書

**バージョン:** 1.0 | **Swift:** 6.0 | **最低iOS:** 17.0 | **推奨iOS:** 26+

## プロジェクト概要

NoteChain はプライバシーファーストの AI 搭載ボイスメモ iOS アプリです。
音声をリアルタイムで文字起こしし、NaturalLanguage フレームワークが自動でキーワードを抽出・タグ付けします。
すべての処理はオンデバイスで完結し、クラウドバックエンドは不要です。

## 技術スタック

| レイヤー         | 技術                                  |
|-----------------|---------------------------------------|
| UI              | SwiftUI 100% 宣言的                   |
| 状態管理        | @Observable + MVVM (@MainActor)       |
| ナビゲーション   | NavigationStack + Router (enum ベース)|
| データ永続化    | SwiftData (iOS 17+)                   |
| 音声認識（主）   | SpeechAnalyzer (iOS 26+)             |
| 音声認識（FB）   | SFSpeechRecognizer (iOS 17-25)       |
| キーワード抽出   | NaturalLanguage (NLTagger) MVP       |
| 課金            | StoreKit 2                            |

## 参照ドキュメント

@docs/PRD.md
@docs/ARCHITECTURE.md

## XcodeBuildMCP コマンド

```
/build    — ビルド実行 (xcodebuild build)
/test     — テスト実行 (xcodebuild test)
/generate-spec [feature]   — PRD から機能仕様書を生成
/generate-tasks [feature]  — 仕様書からタスクリストを生成
/implement-feature [feature] — 指定機能の実装を開始
```

## ディレクトリ構成

```
NoteChain/
├── App/              # @main エントリポイント・AppState・ContentView
├── Features/         # Vertical Slice（各機能が自己完結）
│   ├── Recording/    # 音声録音 & 文字起こし
│   ├── Keywords/     # キーワード抽出
│   ├── NotesList/    # ノート一覧・検索・詳細
│   ├── Settings/     # 設定 & 多言語
│   ├── Subscription/ # StoreKit 2 サブスクリプション
│   └── Onboarding/   # 初回起動フロー
└── Shared/           # 全 Feature が共有するレイヤー
    ├── Models/       # Note @Model, AppError
    ├── Navigation/   # Router
    ├── Services/     # SpeechRecognitionService
    ├── Extensions/   # Date+Formatting など
    └── Components/   # 再利用可能 UI コンポーネント
```

## 開発ワークフロー

```
Plan → Spec → Implement → Test → Review
```

1. **Plan**: `docs/PRD.md` で要件を確認
2. **Spec**: `/generate-spec [feature]` で `docs/specs/[feature].md` を生成
3. **Implement**: `/implement-feature [feature]` で実装開始。`docs/ARCHITECTURE.md` の該当モジュール設計に従う
4. **Test**: `/test` でユニット・UIテストを実行。全テストグリーンを確認
5. **Review**: `.claude/skills/code-review/SKILL.md` の観点でセルフレビュー

## 絶対遵守ルール（5つ）

1. **NEVER** `@ObservedObject` / `@Published` / `ObservableObject` を使う → `@Observable` を使う
2. **ALWAYS** ViewModel は `@MainActor @Observable final class` にする
3. **NEVER** `DispatchQueue.global()` や Combine を使う → `async/await` + `Task` のみ
4. **ALWAYS** UI文字列は `Localizable.xcstrings` のキーを使う（ハードコード禁止）
5. **NEVER** `Shared/` レイヤーから `Features/` レイヤーへ依存する（方向: Features → Shared のみ）

詳細ルールは `.claude/rules/` を参照してください。

## 機能仕様書へのリンク

| 機能 | 仕様書 |
|------|--------|
| 音声録音 & 文字起こし | `docs/specs/recording.md` |
| キーワード抽出 | `docs/specs/keywords.md` |
| ノート一覧 | `docs/specs/notes-list.md` |
| 設定 & 多言語 | `docs/specs/settings.md` |
| サブスクリプション | `docs/specs/subscription.md` |
