---
description: "SwiftData / @Model 規約"
paths:
  - "**/Models/**/*.swift"
---

# NoteChain — SwiftData ルール

## @Model 定義

ALWAYS:   `@Model` は `final class` にのみ付与する。`struct` への適用は禁止。
          ```swift
          @Model
          final class Note { ... }   // ✅
          ```

ALWAYS:   一意識別子には `@Attribute(.unique)` を付与する。
          ```swift
          @Attribute(.unique) var id: UUID
          ```

## ModelContext の使い方

CRITICAL: `@Query` マクロは使用禁止。代わりに ViewModel で `ModelContext.fetch()` を使う。
          理由: テスト時に In-Memory ModelContext を DI できるようにするため。

ALWAYS:   ViewModel のイニシャライザで `ModelContext` を受け取る（依存注入）。
          ```swift
          init(modelContext: ModelContext) {
              self.modelContext = modelContext
          }
          ```

ALWAYS:   View では `@Environment(\.modelContext)` で取得し ViewModel に渡す。

## スレッド安全性

ALWAYS:   メインスレッドでの軽量な読み書きは `@MainActor` ViewModel 内で直接行う。
          大量データの書き込みは `@ModelActor` 隔離 Actor を使う（v1.1 以降）。

## エラーハンドリング

ALWAYS:   `modelContext.save()` は `try/catch` で囲み `AppError.swiftDataSaveFailed` にラップ。
          `try?` での握り潰しは禁止。

## テスト設定

ALWAYS:   テスト用 ModelContainer は `ModelConfiguration(isStoredInMemoryOnly: true)` を使う。
          実際のファイルシステムに書き込まないこと。

## Relationship（将来）

ALWAYS:   Relationship を追加する際は削除ルールを明示する。
          ```swift
          @Relationship(deleteRule: .cascade) var items: [Item]
          ```
