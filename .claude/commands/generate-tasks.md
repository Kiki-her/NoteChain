# /generate-tasks [feature]

指定された機能のタスクリストを `docs/tasks/[feature]-tasks.md` に生成します。

## 入力

`[feature]`: recording / keywords / notes-list / settings / subscription

## 前提条件

`docs/specs/[feature].md` が存在すること。なければ先に `/generate-spec [feature]` を実行。

## 実行手順

1. `docs/specs/[feature].md` を読む
2. `docs/ARCHITECTURE.md` の該当モジュール設計を確認する
3. 以下の形式でタスクリストを生成する

## タスクフォーマット

```markdown
# [Feature] タスクリスト

## 依存関係
- 前提タスク: [他 Feature のタスク]

## タスク一覧

### Phase 1: 基盤
- [ ] T001: [ファイル名].swift を作成（プロトコル定義）
- [ ] T002: [ファイル名].swift を作成（主要実装）

### Phase 2: UI
- [ ] T003: [View名].swift のレイアウト実装
- [ ] T004: Preview の実装

### Phase 3: テスト
- [ ] T005: [Feature]ViewModelTests.swift の Given-When-Then テスト
- [ ] T006: パフォーマンステスト

### Phase 4: 仕上げ
- [ ] T007: ローカライズキーの追加
- [ ] T008: アクセシビリティラベルの追加
```

## タスクの粒度

各タスクは 1-2 時間（AI実装で 15-30 分）で完了できる粒度にすること。
