---
description: "全体ルール（常時ロード）"
---

# NoteChain — 全体ルール

## アーキテクチャ原則

ALWAYS: 実装前に `docs/ARCHITECTURE.md` の該当モジュール設計を確認し、
        プロパティ・メソッド名を設計書と一致させること。

ALWAYS: Vertical Slice を遵守する。機能追加は必ず `Features/<Feature>/` 内に閉じること。
        2つ以上の Feature で使う場合のみ `Shared/` へ昇格させる。

NEVER:  `Shared/` レイヤーから `Features/` レイヤーへ依存してはならない。
        依存方向は `Features → Shared` のみ。Feature 間の連携は `@Environment` 経由。

ALWAYS: ファイル新規作成前に同じ責務を持つファイルが存在しないか検索すること（重複防止）。

## コーディング規約

ALWAYS: UI文字列は必ず `Localizable.xcstrings` のキーを使用する。
        ハードコード文字列（"Record Note" など）は禁止。

NEVER:  `@ObservedObject` / `@Published` / `ObservableObject` を使う。
        `@Observable` + `@State` パターンを使う。

ALWAYS: Magic Number を禁止。定数は `enum Constants` または `extension` で名前付きで定義する。
        例: `3` ではなく `FreeplanLimits.weeklyNoteMax`

ALWAYS: SwiftData は `@Query` マクロを使わず `ModelContext.fetch(FetchDescriptor<T>())` を使う。
        理由: テスト時に MockModelContext を注入できるようにするため。

ALWAYS: 各 Feature ディレクトリの `README.md` に変更内容を反映すること。

NEVER:  TODO コメントをコードに残さない。未実装は GitHub Issue を作成し、コメントに Issue 番号を記載する。

## 依存関係

CRITICAL: `Shared/` → `Features/` の依存は絶対禁止。ビルドエラーになる設計。
CRITICAL: 最低 iOS 17.0 対応。`@available(iOS 17, *)` より古い API は使用しない。
