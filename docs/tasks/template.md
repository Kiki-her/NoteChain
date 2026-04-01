# [機能名] タスクリスト

**バージョン:** 1.0  
**対応仕様書:** `docs/specs/[feature].md`  
**ステータス:** [ ] 未着手 / [in-progress] 進行中 / [x] 完了

---

## 依存関係

- 前提 Feature: （他 Feature のタスクが完了している必要がある場合に記載）
- 前提 Shared: `Note.swift`, `Router.swift` など

---

## タスク一覧

### Phase 1: プロトコル & モデル定義

- [ ] T001: `[Protocol].swift` を作成（プロトコル定義のみ）
- [ ] T002: `[Model]` に必要なプロパティを追加

### Phase 2: コアロジック実装

- [ ] T003: `[ViewModel].swift` の公開プロパティを定義
- [ ] T004: `[ViewModel].[method]()` の実装
- [ ] T005: エラーハンドリングの実装（AppError ラップ）

### Phase 3: UI 実装

- [ ] T006: `[View].swift` のレイアウト実装（骨格）
- [ ] T007: 状態別 UI の実装（ローディング / エラー / 空状態）
- [ ] T008: `#Preview` の実装

### Phase 4: テスト

- [ ] T009: `[Feature]ViewModelTests.swift` の Given-When-Then テスト（正常系）
- [ ] T010: エラーケースのテスト
- [ ] T011: 境界値テスト（空文字列・最大値）
- [ ] T012: パフォーマンステスト（必要な場合）

### Phase 5: 仕上げ

- [ ] T013: `Localizable.xcstrings` にキーを追加（en / ja / es）
- [ ] T014: アクセシビリティラベルの追加
- [ ] T015: `README.md` を更新
- [ ] T016: `/build` でビルドエラーがないことを確認
- [ ] T017: `/test` で全テストがグリーンであることを確認

---

## 進捗

| フェーズ | 完了 / 合計 |
|---------|-----------|
| Phase 1 | 0 / 2     |
| Phase 2 | 0 / 3     |
| Phase 3 | 0 / 3     |
| Phase 4 | 0 / 4     |
| Phase 5 | 0 / 5     |
| **合計** | **0 / 17** |
