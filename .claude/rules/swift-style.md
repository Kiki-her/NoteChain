---
description: "Swift 6 / Concurrency 規約"
paths:
  - "**/*.swift"
---

# NoteChain — Swift 6 スタイルルール

## Actor 分離

CRITICAL: すべての ViewModel クラスは `@MainActor` で隔離すること。
          ```swift
          @MainActor
          @Observable
          final class MyViewModel { ... }
          ```

NEVER:    `nonisolated(unsafe)` を使用してはならない（Swift 6 では危険）。

NEVER:    `@unchecked Sendable` は `LegacySpeechService` のみ許可。
          他への適用は設計書の明示的な承認が必要。

## 非同期処理

CRITICAL: `DispatchQueue.global()` / `DispatchQueue.main.async` / Combine `Publisher` は禁止。
          非同期処理は `async/await` + `Task` のみ使用する。

ALWAYS:   `Task {}` を生成した場合は `task?.cancel()` を `deinit` や `.onDisappear` で呼ぶ。

ALWAYS:   CPU バウンドな処理（NLTagger など）は `Task.detached(priority: .userInitiated)` で
          バックグラウンドに退避させること。

NEVER:    `Task.detached` 内から MainActor プロパティに直接アクセスしてはならない。
          `await MainActor.run { }` または `@MainActor` 関数呼び出しを使う。

## Sendable

ALWAYS:   非同期コンテキストを跨ぐ型は `Sendable` または `@Sendable` を明示する。
          `struct TranscriptionResult: Sendable { ... }`

## エラーハンドリング

NEVER:    `try?` を多用してはならない。`do/catch` で `AppError` にラップして
          ViewModel の `errorMessage` プロパティに格納すること。

ALWAYS:   `CancellationError` は正常終了として扱い、ユーザーにエラー表示しない。

## コードスタイル

ALWAYS:   Apple フレームワーク import を先頭に、アルファベット順で列挙する。
          不要な import は削除する。

ALWAYS:   関数の戻り値型と公開プロパティには型を明示する。ローカル変数は型推論を活用。

ALWAYS:   クラスは `final` を付ける（継承が必要な場合のみ除外）。
