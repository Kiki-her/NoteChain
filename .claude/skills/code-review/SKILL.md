# SKILL: code-review

## 目的

Swift 6 / SwiftUI / セキュリティの観点でコードをレビューするスキル。

## レビューチェックリスト

### Swift 6 Concurrency
- [ ] ViewModel に `@MainActor` が付いているか
- [ ] `@ObservedObject` / `@Published` / `ObservableObject` を使っていないか
- [ ] `DispatchQueue` / Combine を使っていないか
- [ ] `Task` のキャンセルが適切に管理されているか
- [ ] `@unchecked Sendable` の不正使用がないか

### SwiftUI パターン
- [ ] ViewModel は `@State private var viewModel = ...` か
- [ ] `@EnvironmentObject` を使っていないか（`@Environment(Type.self)` を使う）
- [ ] `.task {}` で非同期処理を開始しているか
- [ ] `#Preview` が実装されているか
- [ ] `body` が 100 行以内か

### SwiftData
- [ ] `@Query` マクロを使っていないか
- [ ] `modelContext.save()` が `try/catch` で囲まれているか
- [ ] `@Model` が `final class` か

### セキュリティ
- [ ] `requiresOnDeviceRecognition = true` が設定されているか
- [ ] 音声データをネットワーク送信していないか
- [ ] ログに個人情報（文字起こし）が含まれていないか

### ローカライズ
- [ ] UI文字列がすべて `Localizable.xcstrings` キーか
- [ ] ハードコード文字列がないか

### テスト
- [ ] `XCTestCase` を使っていないか（Swift Testing のみ）
- [ ] MockSpeechService を使っているか
- [ ] InMemory SwiftData を使っているか
