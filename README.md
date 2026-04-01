# NoteChain

[![CI — Build & Test](https://github.com/Kiki-her/NoteChain/actions/workflows/ci-build-test.yml/badge.svg)](https://github.com/Kiki-her/NoteChain/actions/workflows/ci-build-test.yml)
[![CD — TestFlight](https://github.com/Kiki-her/NoteChain/actions/workflows/cd-testflight.yml/badge.svg)](https://github.com/Kiki-her/NoteChain/actions/workflows/cd-testflight.yml)
[![AI Review](https://github.com/Kiki-her/NoteChain/actions/workflows/gemini-review.yml/badge.svg)](https://github.com/Kiki-her/NoteChain/actions/workflows/gemini-review.yml)

プライバシーファーストの AI 搭載ボイスメモ iOS アプリ。  
音声をリアルタイムで文字起こしし、キーワードを自動抽出・タグ付け。**すべての処理はオンデバイスで完結**し、クラウドバックエンドは不要です。

- **対応 OS**: iOS 17.0 以上（iOS 26+ 推奨）
- **言語**: Swift 6.0 / SwiftUI / SwiftData
- **多言語**: 英語 / 日本語 / スペイン語
- **マネタイズ**: StoreKit 2（月額 $3.99 / 年額 $29.99、14日無料トライアル）

---

## 開発を始める前に

### 1. Gemini CLI のインストール

AI レビュー・リリースノート生成に使用します（Node.js 18+ が必要）。

```bash
# Node.js インストール（未インストールの場合）
brew install node

# Gemini CLI をグローバルインストール
npm install -g @google/gemini-cli

# 動作確認
gemini --version

# API キーを設定（Google AI Studio で取得: https://aistudio.google.com/apikey）
export GEMINI_API_KEY="your_api_key_here"

# ~/.zshrc or ~/.bashrc に追記して永続化
echo 'export GEMINI_API_KEY="your_api_key_here"' >> ~/.zshrc
```

### 2. XcodeBuildMCP のセットアップ

Claude Code / Gemini CLI から xcodebuild を呼び出すための MCP サーバーです。

```bash
# npx 経由で自動インストール（.mcp.json 設定済み）
npx -y xcodebuildmcp@latest --help

# Claude Code を使う場合: .mcp.json が自動読み込まれます
# Gemini CLI を使う場合: GEMINI.md の設定に従います
```

> **`.mcp.json` の内容**: プロジェクトルートに配置済み。`xcodebuildmcp@latest` を npx 経由で起動します。

### 3. Fastlane のセットアップ（CD のみ必要）

```bash
# Bundler をインストール
gem install bundler

# Gemfile がある場合（推奨）
bundle install

# Gemfile がない場合
gem install fastlane

# 動作確認
bundle exec fastlane --version
# または
fastlane --version
```

### 4. 開発環境の要件

| 項目 | 要件 |
|------|------|
| Xcode | 26.3 以上 |
| Swift | 6.0 |
| macOS | 15 (Sequoia) 以上 |
| iOS Simulator | iPhone 16 Pro, iOS 18+ |
| Ruby | 3.2 以上（Fastlane 用） |
| Node.js | 18 以上（Gemini CLI 用） |

---

## ビルド & テスト

```bash
# デバッグビルド
xcodebuild \
  -scheme NoteChain \
  -project NoteChain.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  build

# テスト実行（Swift Testing）
xcodebuild \
  -scheme NoteChain \
  -project NoteChain.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  -configuration Debug \
  -enableCodeCoverage YES \
  test

# Fastlane でテスト（推奨）
bundle exec fastlane tests
```

---

## CI/CD

### GitHub Secrets の登録

リポジトリの **Settings → Secrets and variables → Actions** から登録してください。

| Secret 名 | 必須 | 用途 | 取得元 |
|-----------|------|------|-------|
| `GOOGLE_API_KEY` | ✅ | Gemini CLI コードレビュー・リリースノート生成 | [Google AI Studio](https://aistudio.google.com/apikey) |
| `ASC_KEY_ID` | ✅（CD） | App Store Connect API Key ID | App Store Connect → ユーザーとアクセス → 統合 |
| `ASC_ISSUER_ID` | ✅（CD） | App Store Connect Issuer ID | 同上 |
| `ASC_PRIVATE_KEY` | ✅（CD） | .p8 ファイルの内容（改行込み） | 同上（キー生成時のみ DL 可） |
| `MATCH_PASSWORD` | ✅（CD） | Match 証明書リポジトリの暗号化パスワード | 任意の強力なパスワードを設定 |
| `MATCH_GIT_URL` | ✅（CD） | Match 証明書リポジトリ URL | プライベートリポジトリを作成して設定 |
| `MATCH_GIT_TOKEN` | CD推奨 | Match リポジトリへの PAT | GitHub Settings → Developer settings → PAT (repo スコープ) |

> **`GITHUB_TOKEN`** は GitHub Actions が自動で付与するため、登録不要です。

### ワークフロー詳細

#### ① CI — Build & Test（`ci-build-test.yml`）

```
トリガー: push → main, develop
         pull_request → main
ランナー: macos-15
```

| ステップ | 内容 |
|---------|------|
| Xcode 26.3 選択 | `xcode-select` で Xcode バージョンを固定 |
| SPM キャッシュ | `Package.resolved` ハッシュでキャッシュ |
| ビルド | `CODE_SIGNING_ALLOWED=NO`, `SWIFT_STRICT_CONCURRENCY=complete` |
| テスト | Swift Testing, JUnit XML 出力, xcresult 保存 |
| カバレッジ | `xccov` でレポート生成 → Step Summary に表示 |
| Artifacts | JUnit XML (30日), xcresult (14日) |

#### ② AI Review — Gemini CLI（`gemini-review.yml`）

```
トリガー: pull_request [opened, synchronize, reopened]
         *.swift / *.yaml / *.yml / *.json の変更時のみ
ランナー: ubuntu-latest
Secret:  GOOGLE_API_KEY
```

Swift diff を Gemini 2.5 Flash に送り、以下の観点でレビュー → PR コメントとして投稿：

- Swift 6 Strict Concurrency 違反
- `@Observable` パターン遵守（`@ObservedObject` 禁止）
- SwiftData パターン（`@Query` 禁止）
- Vertical Slice アーキテクチャ違反
- セキュリティ・プライバシー要件
- ローカライズ漏れ

#### ③ CD — TestFlight（`cd-testflight.yml`）

```
トリガー: push tags v*  （例: git tag v1.0.0 && git push origin v1.0.0）
ランナー: macos-15
Secrets: ASC_KEY_ID, ASC_ISSUER_ID, ASC_PRIVATE_KEY, MATCH_PASSWORD
```

`fastlane beta` レーンを実行：

1. App Store Connect API 認証
2. Match で証明書・プロファイル同期（readonly）
3. ビルド番号自動インクリメント（タイムスタンプ）
4. `build_app`（アーカイブ + エクスポート）
5. `upload_to_testflight`

#### ④ Release Notes — Gemini CLI（`gemini-changelog.yml`）

```
トリガー: release [published]
ランナー: ubuntu-latest
Secret:  GOOGLE_API_KEY
```

前回タグからのコミット一覧を Gemini CLI に渡し、日英バイリンガルのリリースノートを自動生成して GitHub Release の本文を更新します。

---

### リリースフロー

```bash
# 1. develop から release ブランチを作成
git checkout develop
git pull origin develop
git checkout -b release/v1.0.0

# 2. バージョン番号を更新
agvtool new-marketing-version 1.0.0

# 3. コミット
git add .
git commit -m "chore(release): bump version to 1.0.0"

# 4. PR を main に作成（GitHub Web UI または gh コマンド）
gh pr create --base main --head release/v1.0.0 \
  --title "release: v1.0.0" \
  --body "CI + CodeRabbit + Gemini レビューを確認してからマージ"

# 5. レビュー通過後、main にマージ

# 6. タグをプッシュ → cd-testflight.yml が自動実行
git checkout main && git pull origin main
git tag v1.0.0
git push origin v1.0.0

# 7. GitHub Releases で "Publish release" を作成
#    → gemini-changelog.yml が日英リリースノートを自動生成
```

---

## プロジェクト構造

```
NoteChain/
├── App/                   # @main エントリポイント・AppState・ContentView
├── Features/              # Vertical Slice（各機能が自己完結）
│   ├── Recording/         # 音声録音 & リアルタイム文字起こし
│   ├── Keywords/          # NLTagger キーワード抽出
│   ├── NotesList/         # ノート一覧・検索・詳細
│   ├── Settings/          # 設定 & 多言語対応
│   ├── Subscription/      # StoreKit 2 サブスクリプション管理
│   └── Onboarding/        # 初回起動フロー（3ステップ）
└── Shared/                # 全 Feature が共有する層
    ├── Models/            # Note @Model, AppError
    ├── Navigation/        # Router (@Observable), Route enum
    ├── Services/          # SpeechRecognitionService + Factory
    ├── Extensions/        # Date+Formatting, String+Localized
    └── Components/        # EmptyStateView, LoadingOverlay 等

NoteChainTests/            # Swift Testing テストスイート
docs/                      # PRD.md, ARCHITECTURE.md, specs/, tasks/
fastlane/                  # Fastfile, Appfile, Matchfile
.github/workflows/         # CI/CD ワークフロー 4本
.claude/                   # Claude Code ルール・スキル・コマンド
```

---

## ドキュメント

| ドキュメント | 内容 |
|------------|------|
| [`docs/PRD.md`](docs/PRD.md) | プロダクト要件定義 |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | アーキテクチャ設計書 |
| [`docs/SETUP_CHECKLIST.md`](docs/SETUP_CHECKLIST.md) | 初回セットアップチェックリスト |
| [`CLAUDE.md`](CLAUDE.md) | Claude Code 向け指示書 |
| [`GEMINI.md`](GEMINI.md) | Gemini CLI 向け指示書 |
| [`AGENTS.md`](AGENTS.md) | AI エージェント共通ルール |

---

## ライセンス

© 2026 NoteChain. All rights reserved.
