---
description: "Swift Testing 規約"
paths:
  - "**/*Tests.swift"
---

# NoteChain — テストルール

## フレームワーク

CRITICAL: `XCTestCase` は使用禁止。すべてのテストは `import Testing` + `@Suite` / `@Test`。
          ```swift
          import Testing
          @Suite("RecordingViewModel Tests")
          struct RecordingViewModelTests { ... }
          ```

ALWAYS:   テストメソッドには `@Test` アノテーションを付与し、
          Given-When-Then 形式でテスト意図を明示する。
          ```swift
          @Test("Given: empty text, When: extract keywords, Then: returns empty array")
          func extractKeywords_emptyText_returnsEmpty() async { ... }
          ```

## アサーション

ALWAYS:   `#expect(value == expected)` を使う。`XCTAssertEqual` は使わない。
ALWAYS:   非同期テストは `async throws` で宣言する。
          `XCTestExpectation` / `waitForExpectations` は使わない。

## テスト用モック

ALWAYS:   `SpeechRecognitionServiceProtocol` を実装した `MockSpeechService` をテストで使う。
          実際の AVAudioEngine / SpeechAnalyzer は呼ばない（シミュレータ制限のため）。

ALWAYS:   SwiftData は `ModelConfiguration(isStoredInMemoryOnly: true)` で InMemory コンテナを使う。
          ```swift
          let config = ModelConfiguration(isStoredInMemoryOnly: true)
          let container = try ModelContainer(for: Note.self, configurations: config)
          ```

## テスト品質

ALWAYS:   境界値テストを含める（空文字列・1000件・極短・極長テキスト等）。

ALWAYS:   パフォーマンスアサーションを含める。
          - キーワード抽出: 100語テキストで 1秒以内
          - ノート検索: 1000件で 500ms 以内

ALWAYS:   各テストは独立させる。`@Suite` の `init()` でセットアップ、`deinit` でクリーンアップ。

## カバレッジ目標

ALWAYS:   ViewModel / Service クラスのテストカバレッジ 80% 以上を目指す。
          UIテストは主要フロー（録音・ペイウォール・言語切り替え）のみ。
