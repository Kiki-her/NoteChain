# SKILL: implement-feature

## 目的

PRD の機能仕様から実装・テストまでの一貫したワークフローを実行するスキル。

## ワークフロー

### Step 1: 仕様書を読む

```
Read: docs/specs/[feature].md
```

仕様書が存在しない場合は `/generate-spec [feature]` を先に実行する。

確認事項:
- ユーザーフロー
- 受け入れ基準（Given-When-Then）
- 技術制約
- 依存する他モジュール

### Step 2: タスクリストを読む

```
Read: docs/tasks/[feature]-tasks.md
```

タスクリストが存在しない場合は `/generate-tasks [feature]` を先に実行する。

現在のタスクを特定し、`[ ]` → `[in-progress]` に更新する。

### Step 3: 現在のタスクを実装する

実装前チェック:
- `docs/ARCHITECTURE.md` の該当モジュール設計を確認
- 既存ファイルがある場合は必ず読んでから編集
- `.claude/rules/` の関連ルールを確認

実装ガイドライン:
- ViewModel は `@MainActor @Observable final class`
- View は `@State private var viewModel = XxxViewModel(...)`
- エラーは `AppError` にラップして `viewModel.errorMessage` に格納
- すべての文字列は `Localizable.xcstrings` キー経由

### Step 4: テストを書いて実行する

テストファイル: `NoteChainTests/Features/[Feature]/[Feature]ViewModelTests.swift`

テスト規約:
- `import Testing` のみ（XCTestCase 不使用）
- `@Suite` / `@Test` アノテーション
- Given-When-Then 形式のテスト名
- MockSpeechService / InMemory ModelContainer を使用

```
/test
```

すべてのテストがグリーンになるまで修正する。

### Step 5: タスクファイルを更新する

完了したタスクを `[in-progress]` → `[x]` に更新する。
発見した新しいタスクがあれば追加する。

### Step 6: 次のタスクの承認を求める

```
タスク "[タスク名]" が完了しました。
次のタスクは "[次のタスク名]" です。
実装を進めてよいですか？
```

人間のレビューを待ってから次のタスクに進む。
