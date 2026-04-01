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

## CI/CD ルール

### ブランチ戦略

| ブランチ        | 用途                                           | 保護 |
|----------------|------------------------------------------------|------|
| `main`         | 本番リリースブランチ。直接プッシュ禁止。        | ✅ |
| `develop`      | 開発ブランチ。Feature ブランチからの PR をマージ。| ✅ |
| `feature/*`    | 機能開発ブランチ。develop から分岐、develop に PR。| - |
| `release/v*`   | リリース準備ブランチ。タグ付け�� TestFlight デプロイ。| - |

### PR ルール

- **NEVER** CodeRabbit の自動レビューが完了する前にマージする
- **NEVER** CI (build + test) が失敗しているままマージする
- **NEVER** Gemini レビューで CRITICAL 指摘がある場合にマージする
- **ALWAYS** セルフレビュー後に PR を作成する（`.claude/skills/code-review/SKILL.md` 参照）

### ワークフロー一覧

| ファイル | トリガー | ランナー | 目的 |
|---------|---------|---------|------|
| `ci-build-test.yml` | push(main/develop), PR→main | macos-15 | Xcode 26.3 ビルド + Swift Testing |
| `gemini-review.yml` | PR opened/sync | ubuntu-latest | Gemini CLI による Swift コードレビュー |
| `cd-testflight.yml` | push tag `v*` | macos-15 | Fastlane beta → TestFlight |
| `gemini-changelog.yml` | release published | ubuntu-latest | リリースノート自動生成（日英） |

### リリースフロー

```
1. develop から release/vX.X.X ブランチを作成
2. バージョン番号を更新（agvtool new-marketing-version X.X.X）
3. PR を main に作成 → CI (build+test) + CodeRabbit + Gemini レビュー通過
4. main にマージ後、git tag vX.X.X && git push origin vX.X.X
5. cd-testflight.yml が自動実行 → TestFlight アップロード
6. GitHub Releases で "Publish release" → gemini-changelog.yml が日英リリースノート生成
```

### 必要な GitHub Secrets

| Secret 名 | 用途 | 取得元 |
|-----------|------|-------|
| `GOOGLE_API_KEY` | Gemini CLI API キー | https://aistudio.google.com/apikey |
| `ASC_KEY_ID` | App Store Connect API Key ID | App Store Connect > ユーザーとアクセス > 統合 |
| `ASC_ISSUER_ID` | App Store Connect Issuer ID | 同上 |
| `ASC_PRIVATE_KEY` | .p8 ファイル内容（改行込み） | 同上（キー生成時のみダウンロード可） |
| `MATCH_PASSWORD` | Match 証明書リポジトリの暗号化パスワード | 任意の強力なパスワード |
| `MATCH_GIT_URL` | Match 証明書リポジトリ URL | プライベートリポジトリ URL |
| `MATCH_GIT_TOKEN` | Match リポジトリへの PAT | GitHub Settings > Developer settings > PAT |
