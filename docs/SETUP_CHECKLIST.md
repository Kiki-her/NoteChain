# NoteChain — 初回セットアップチェックリスト

> このチェックリストは NoteChain の開発環境と CI/CD パイプラインを初めて構築する際に使用してください。  
> 上から順に実施し、各項目が完了したらチェックを入れてください。

---

## Phase 1: リポジトリ & GitHub 設定

### 1-1. GitHub リポジトリ設定

- [ ] GitHub でリポジトリを **public** で作成済み（CodeRabbit Free は public リポジトリのみ対応）
- [ ] デフォルトブランチが `main` であることを確認
- [ ] **Settings → Branches** でブランチ保護ルールを設定：
  - [ ] `main`: "Require a pull request before merging" を ON
  - [ ] `main`: "Require status checks to pass before merging" を ON（CI 緑後）
  - [ ] `develop`: "Require a pull request before merging" を ON（任意）

### 1-2. CodeRabbit のセットアップ

- [ ] [CodeRabbit GitHub App](https://github.com/apps/coderabbitai) をリポジトリにインストール
- [ ] `.coderabbit.yaml` がリポジトリルートに存在することを確認
  ```bash
  cat .coderabbit.yaml | head -5
  # language: "ja" が設定されていれば OK
  ```
- [ ] PR を1件テスト作成し、CodeRabbit が日本語でレビューを投稿することを確認

---

## Phase 2: GitHub Secrets の登録

**Settings → Secrets and variables → Actions → New repository secret** から登録します。

### 2-1. Gemini CLI 用（CI Review ワークフロー必須）

- [ ] `GOOGLE_API_KEY` を登録
  ```
  取得元: https://aistudio.google.com/apikey
  値の例: AIzaSy...（39文字）
  ```

### 2-2. App Store Connect 用（CD ワークフロー必須）

- [ ] `ASC_KEY_ID` を登録
  ```
  取得元: App Store Connect → ユーザーとアクセス → 統合 → App Store Connect API
  値の例: XXXXXXXXXX（10文字の英数字）
  ```
- [ ] `ASC_ISSUER_ID` を登録
  ```
  取得元: 同上（ページ上部の Issuer ID）
  値の例: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx（UUID形式）
  ```
- [ ] `ASC_PRIVATE_KEY` を登録
  ```
  取得元: 上記ページでキーを生成 → .p8 ファイルをダウンロード
  値: .p8 ファイルの中身をそのまま貼り付け（-----BEGIN PRIVATE KEY----- から EOF まで）
  注意: キーはダウンロード時の1回しか取得できない
  ```

### 2-3. Fastlane Match 用（CD ワークフロー必須）

- [ ] Match 用のプライベートリポジトリを GitHub で作成（例: `your-org/notechain-certificates`）
- [ ] `MATCH_PASSWORD` を登録
  ```
  値: 証明書リポジトリ暗号化用の強力なパスワード（自分で決める）
  例: openssl rand -base64 32 で生成
  ```
- [ ] `MATCH_GIT_URL` を登録
  ```
  値の例: https://github.com/your-org/notechain-certificates.git
  ```
- [ ] `MATCH_GIT_TOKEN` を登録
  ```
  取得元: GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
  スコープ: repo（プライベートリポジトリへの読み取り権限）
  値の例: ghp_xxxx...
  ```

### 2-4. 登録確認

- [ ] Settings → Secrets で以下の7件がすべて登録されていることを確認：
  - [ ] `GOOGLE_API_KEY`
  - [ ] `ASC_KEY_ID`
  - [ ] `ASC_ISSUER_ID`
  - [ ] `ASC_PRIVATE_KEY`
  - [ ] `MATCH_PASSWORD`
  - [ ] `MATCH_GIT_URL`
  - [ ] `MATCH_GIT_TOKEN`

---

## Phase 3: ローカル開発環境

### 3-1. 必須ツールのインストール

- [ ] **Xcode 26.3** 以上がインストール済み
  ```bash
  xcodebuild -version
  # Xcode 26.3 が表示されれば OK
  ```
- [ ] **Node.js 20** 以上がインストール済み
  ```bash
  node --version
  # v20.x.x 以上が表示されれば OK
  ```
- [ ] **Gemini CLI** がインストール済み
  ```bash
  npm install -g @google/gemini-cli
  gemini --version
  ```
- [ ] **GEMINI_API_KEY** がローカル環境変数に設定済み
  ```bash
  export GEMINI_API_KEY="AIzaSy..."
  # ~/.zshrc に追記して永続化
  ```
- [ ] **Ruby 3.2** 以上がインストール済み
  ```bash
  ruby --version
  # ruby 3.2.x が表示されれば OK
  ```
- [ ] **Fastlane** がインストール済み
  ```bash
  gem install fastlane
  fastlane --version
  # fastlane x.x.x が表示されれば OK
  ```

### 3-2. Fastlane の初期設定

- [ ] `fastlane/Appfile` のプレースホルダーを実値に置換
  ```ruby
  # fastlane/Appfile
  app_identifier "com.yourcompany.notechain"  # ← 実際の Bundle ID
  apple_id "you@example.com"                  # ← Apple ID
  team_id "XXXXXXXXXX"                         # ← Team ID
  ```
- [ ] `fastlane/Matchfile` の `git_url` を実際の証明書リポジトリ URL に更新
  ```ruby
  # fastlane/Matchfile
  git_url "https://github.com/your-org/notechain-certificates.git"  # ← 実際の URL
  ```
- [ ] Match を初期化（初回のみ）
  ```bash
  bundle exec fastlane match_init
  # または
  fastlane match_init
  ```
- [ ] 証明書・プロファイルを生成
  ```bash
  bundle exec fastlane match development
  bundle exec fastlane match appstore
  ```

### 3-3. ローカルビルド検証

- [ ] ビルドが成功することを確認
  ```bash
  xcodebuild \
    -scheme NoteChain \
    -project NoteChain.xcodeproj \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
    -configuration Debug \
    CODE_SIGNING_ALLOWED=NO \
    build 2>&1 | tail -5
  # ** BUILD SUCCEEDED ** が表示されれば OK
  ```
- [ ] テストが通ることを確認
  ```bash
  bundle exec fastlane tests
  # または
  xcodebuild test \
    -scheme NoteChain \
    -project NoteChain.xcodeproj \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
    CODE_SIGNING_ALLOWED=NO \
    test 2>&1 | tail -5
  # ** TEST SUCCEEDED ** が表示されれば OK
  ```
- [ ] Gemini CLI でローカルレビューが動作することを確認
  ```bash
  echo "// Test Swift code\nfunc hello() { print(\"world\") }" \
    | gemini --yolo -m gemini-2.5-flash -p "この Swift コードをレビューしてください"
  # レビュー結果が出力されれば OK
  ```

---

## Phase 4: CI パイプライン検証

### 4-1. CI ビルド & テストの確認

- [ ] `develop` ブランチに適当な変更をプッシュ
  ```bash
  git checkout develop
  echo "# test" >> README.md
  git add . && git commit -m "test: CI pipeline verification"
  git push origin develop
  ```
- [ ] GitHub Actions の **Actions タブ** で `CI — Build & Test` が実行されることを確認
- [ ] ワークフローが **緑（成功）** になることを確認
- [ ] Artifacts に `test-results-junit` と `test-results-xcresult` が生成されることを確認

### 4-2. Gemini レビューの確認

- [ ] `develop` から `feature/test-ci` ブランチを作成し、Swift ファイルを変更
  ```bash
  git checkout -b feature/test-ci develop
  # NoteChain/ 内の任意の .swift ファイルを小さく変更
  git add . && git commit -m "test: trigger Gemini review"
  git push origin feature/test-ci
  ```
- [ ] GitHub で `develop` への PR を作成
- [ ] `AI Review — Gemini CLI` ワークフローが実行されることを確認
- [ ] PR コメントに Gemini のレビュー結果が投稿されることを確認
- [ ] PR をクローズ（`feature/test-ci` ブランチも削除）

### 4-3. CodeRabbit レビューの確認

- [ ] 上記 4-2 のテスト PR で CodeRabbit も日本語レビューを投稿したことを確認
  - `.coderabbit.yaml` の `language: "ja"` 設定が反映されていれば日本語になります

---

## Phase 5: CD パイプライン検証

### 5-1. TestFlight ワークフローの確認（テストタグ）

- [ ] Fastlane 設定が完了していることを前提に実施
- [ ] テスト用タグをプッシュ
  ```bash
  git checkout main
  git pull origin main
  git tag v0.0.1-test
  git push origin v0.0.1-test
  ```
- [ ] `CD — TestFlight Deploy` ワークフローが起動することを確認
- [ ] ワークフローが完走し、App Store Connect の TestFlight にビルドが表示されることを確認
  - （処理に数分〜10分程度かかります）
- [ ] テストタグを削除（本番タグと混同を避けるため）
  ```bash
  git push origin --delete v0.0.1-test
  git tag -d v0.0.1-test
  ```

### 5-2. リリースノート自動生成の確認

- [ ] GitHub Releases で "Draft a new release" をクリック
- [ ] タグ `v0.0.1-test` を選択（または新規タグ `v0.0.1` を作成）
- [ ] "Publish release" をクリック
- [ ] `Release Notes — Gemini CLI` ワークフローが起動することを確認
- [ ] Release の本文が日英バイリンガルのリリースノートに更新されることを確認

---

## Phase 6: 最終確認

- [ ] GitHub Actions の全ワークフローが表示されている（Actions タブで確認）
  - [ ] `CI — Build & Test`
  - [ ] `AI Review — Gemini CLI`
  - [ ] `CD — TestFlight Deploy`
  - [ ] `Release Notes — Gemini CLI`
- [ ] README.md のバッジリンクがすべて機能している
- [ ] `docs/ARCHITECTURE.md` と `docs/PRD.md` が最新の状態である
- [ ] `fastlane/Appfile` と `fastlane/Matchfile` にプレースホルダーが残っていない
- [ ] チーム全員が GOOGLE_API_KEY をローカルに設定済み
- [ ] ブランチ保護ルールが `main` と `develop` に設定済み

---

## トラブルシューティング

### CI が失敗する場合

```bash
# ローカルで再現確認
xcodebuild build \
  -scheme NoteChain \
  -project NoteChain.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | grep -E "error:|warning:|BUILD"
```

### Gemini レビューが "失敗" になる場合

1. `GOOGLE_API_KEY` が正しく登録されているか確認（Settings → Secrets）
2. Google AI Studio の API キーが有効か確認（https://aistudio.google.com/apikey）
3. 無料枠の制限（1,500 req/day）に達していないか確認

### TestFlight デプロイが失敗する場合

1. ASC_KEY_ID / ASC_ISSUER_ID / ASC_PRIVATE_KEY が正しいか確認
2. Match 証明書リポジトリへのアクセス権（MATCH_GIT_TOKEN）を確認
3. ローカルで `bundle exec fastlane beta` を実行して詳細なエラーを確認
4. App Store Connect でバンドル ID が登録済みか確認

### Match パスワードを忘れた場合

```bash
# Match リポジトリのファイルを全消去して再生成（証明書も失効するため注意）
bundle exec fastlane match nuke development
bundle exec fastlane match nuke distribution
bundle exec fastlane match development
bundle exec fastlane match appstore
```

---

> **更新履歴**
> - 2026-04-01: 初版作成
