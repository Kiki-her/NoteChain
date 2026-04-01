# SKILL: test-generator

## 目的

ViewModel に対応する Swift Testing テストファイルを自動生成するスキル。

## 生成ルール

1. 対象 ViewModel のソースファイルを読む
2. 公開プロパティとメソッドを列挙する
3. 各メソッドに対して Given-When-Then テストを生成する
4. MockSpeechService と InMemory ModelContainer を使う

## 生成テンプレート

```swift
import Foundation
import Testing
import SwiftData
@testable import NoteChain

@Suite("[FeatureName] Tests")
struct [FeatureName]ViewModelTests {

    var container: ModelContainer
    var context: ModelContext
    var viewModel: [FeatureName]ViewModel

    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Note.self, configurations: config)
        context = ModelContext(container)
        viewModel = [FeatureName]ViewModel(modelContext: context)
    }

    // MARK: - [メソッド名] Tests

    @Test("Given: [前提条件], When: [操作], Then: [期待結果]")
    func [methodName]_[condition]_[expectedResult]() async throws {
        // Arrange
        // ...

        // Act
        // await viewModel.[method]()

        // Assert
        // #expect(viewModel.[property] == expected)
    }
}
```

## 境界値テストの生成

以下の境界値は必ず生成する:
- 空文字列・nil 入力
- 最大値（1000件、長文テキスト）
- エラーケース（権限拒否、ネットワーク不可等）

## パフォーマンステスト

キーワード抽出・検索系のメソッドには以下を追加:
```swift
@Test("Performance: 100-word text keyword extraction < 1 second")
func keywordExtraction_100Words_completesUnder1Second() async {
    let start = Date()
    let _ = await extractor.extractAsync(from: longText, maxKeywords: 5)
    let elapsed = Date().timeIntervalSince(start)
    #expect(elapsed < 1.0)
}
```
