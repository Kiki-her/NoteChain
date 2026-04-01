# /build

XcodeBuildMCP 経由でプロジェクトをビルドします。

## 実行コマンド

```
mcp__XcodeBuildMCP__build_run_destination_specifier(
  scheme: "NoteChain",
  destination: "platform=iOS Simulator,name=iPhone 16,OS=latest"
)
```

## ビルド成功の確認

- エラー 0、警告 0 を確認する
- Swift 6 Concurrency 警告が出た場合は `.claude/rules/swift-style.md` を参照して修正する

## よくあるビルドエラー

- `@MainActor` 分離違反 → ViewModel に `@MainActor` を追加
- `Sendable` 違反 → `TranscriptionResult` 等が `Sendable` 準拠しているか確認
- `@Model` 制約違反 → `final class` に変更されているか確認
