# /test

XcodeBuildMCP 経由でテストを実行します。

## 実行コマンド

```
mcp__XcodeBuildMCP__test_run_destination_specifier(
  scheme: "NoteChain",
  destination: "platform=iOS Simulator,name=iPhone 16,OS=latest"
)
```

## テスト確認事項

- すべてのテストがグリーン（passed）であること
- カバレッジ: ViewModel / Service クラスで 80% 以上
- パフォーマンステスト: キーワード抽出 < 1秒、検索 < 500ms

## テスト失敗時の対応

1. 失敗したテストの名前と Given-When-Then 条件を確認する
2. 対応する ViewModel / Service のロジックを修正する
3. 再度 `/test` を実行して全テストグリーンを確認する
4. `.claude/rules/testing.md` で MockSpeechService と InMemory SwiftData の使用を確認
