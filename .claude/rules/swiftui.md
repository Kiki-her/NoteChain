---
description: "SwiftUI 固有パターン規約"
paths:
  - "**/*View.swift"
---

# NoteChain — SwiftUI ルール

## ViewModel バインディング

CRITICAL: View 内 ViewModel は `@State private var viewModel = XxxViewModel(...)` のみ。
          `@StateObject` / `@ObservedObject` は絶対に使わない。

ALWAYS:   グローバル共有オブジェクトは `@Environment(XxxType.self)` で受け取る。
          `@EnvironmentObject` は使わない（@Observable と非互換）。

## 非同期処理の起動

ALWAYS:   View 表示時の非同期処理は `.task { await viewModel.load() }` を使う。
          `.onAppear { Task { } }` パターンは禁止（Task のライフサイクル管理が困難）。

NEVER:    View の `body` 内で直接 `Task {}` を生成してはならない。

## View の構造

ALWAYS:   `body` は 100 行以内に収める。超える場合はサブビューを `@ViewBuilder` 関数か
          独立した `struct` に抽出すること。

ALWAYS:   インタラクティブ要素には `.accessibilityLabel()` を付与する。
          装飾的な画像には `.accessibilityHidden(true)` を設定する。

## Preview

ALWAYS:   すべての View に `#Preview {}` を実装すること。
          ViewModel の依存（ModelContext, SubscriptionManager 等）はモックを渡す。
          ```swift
          #Preview {
              RecordingView()
                  .environment(SubscriptionManager.preview)
          }
          ```

## ローカライズ

ALWAYS:   テキストはすべて `Text("localization_key")` 形式。
          `Text("Record Note")` のようなハードコードは禁止。

## アニメーション

ALWAYS:   状態変化アニメーションは `.animation(.easeInOut, value: someState)` で明示的に指定。
          暗黙的アニメーションは使わない。

## レイアウト

NEVER:    `GeometryReader` を多用しない。SwiftUI のネイティブレイアウト API を優先する。
          どうしても必要な場合のみ局所的に使用する。
