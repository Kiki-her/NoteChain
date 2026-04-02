# タスク分割: 音声録音 & リアルタイム文字起こし（Recording モジュール）
 
**機能ID:** FEAT-001  
**バージョン:** 1.0  
**作成日:** 2026-04-02  
**依拠仕様書:** `docs/specs/recording.md`
 
---
 
## 依存関係グラフ
 
```
Task-1 (RecordingManager)
    └── Task-2 (SpeechAnalyzerService)
            └── Task-4 (RecordingViewModel)
Task-3 (LegacySpeechService)  ──┘
                                    └── Task-5 (RecordingView)
                                            └── Task-6 (Note保存・Keyword連携)
                                                    ├── Task-7 (ViewModelテスト)
                                                    └── Task-8 (UIテスト E2E)
```
 
---
 
## Task 1: RecordingManager 基盤（AVAudioEngine + 権限管理）
 
**推定行数:** 120–150 行  
**新規ファイル:** 1（`RecordingManager.swift`）  
**更新ファイル:** 0  
**依存タスク:** なし（独立して着手可能）
 
### 実装内容
 
`NoteChain/Features/Recording/RecordingManager.swift` を実装する。
 
- `AVAudioSession` のカテゴリ設定（`.record`, `.measurement`, `.duckOthers`）
- `setActive(true/false, options: .notifyOthersOnDeactivation)`
- 電話着信などの割り込み通知（`AVAudioSession.interruptionNotification`）の購読と処理
  - `.began` → `isAudioSessionActive = false`
  - `.ended` + `shouldResume` フラグのチェック
- ルート変更通知（`routeChangeNotification`）での Bluetooth マイク対応
- `configureAudioSession() throws` / `deactivateAudioSession()` の公開 API
 
**権限リクエスト（同ファイルに含める）:**
- `AVAudioApplication.requestRecordPermission()` → `Bool`
- `SFSpeechRecognizer.requestAuthorization(_:)` → `SFSpeechRecognizerAuthorizationStatus`
- 両権限の現在ステータスを返す `checkPermissionStatus() -> PermissionStatus` enum
 
### 完了条件（Given-When-Then）
 
- **Given:** iOS シミュレータで `RecordingManager` を初期化した  
  **When:** `configureAudioSession()` を呼ぶ  
  **Then:** エラーなく完了し `isAudioSessionActive == true` になる
 
- **Given:** `AVAudioSession.interruptionNotification` を手動で `.began` で post した  
  **When:** `handleAudioSessionInterruption` が呼ばれる  
  **Then:** `isAudioSessionActive == false` になる
 
- **Given:** マイク権限が `.denied` の状態  
  **When:** `checkPermissionStatus()` を呼ぶ  
  **Then:** `.denied` を返す（実機・シミュレータ共に）
 
---
 
## Task 2: SpeechAnalyzerService（iOS 26+ 実装）
 
**推定行数:** 120–150 行  
**新規ファイル:** 1（`SpeechRecognitionService.swift`）  
**更新ファイル:** 0  
**依存タスク:** Task 1（`configureAudioSession` の確認後に実装）
 
### 実装内容
 
`NoteChain/Shared/Services/SpeechRecognitionService.swift` に以下を実装する。
 
- `TranscriptionResult` 構造体（`text`, `isFinal`, `confidence`, `timestamp`）
- `SpeechRecognitionServiceProtocol` プロトコル定義
- `@available(iOS 26, *) final class SpeechAnalyzerService` の完全実装
  - `SpeechTranscriber(locale:preset: .progressiveLiveTranscription)` 初期化
  - `SpeechAnalyzer(modules: [transcriber])` 起動
  - `for try await result in transcriber.results` ループで `AsyncThrowingStream` に配信
  - `result.isFinal` に応じて `TranscriptionResult.isFinal` をセット
  - `stopRecognition()` で `analyzer.finalizeAndFinishThroughEndOfInput()` を呼ぶ
- `SpeechRecognitionServiceFactory.create()` の `#available(iOS 26, *)` 分岐（LegacySpeechService はスタブで可）
 
### 完了条件（Given-When-Then）
 
- **Given:** iOS 26 シミュレータで `SpeechAnalyzerService` を初期化した  
  **When:** `startRecognition(locale: Locale(identifier: "en-US"))` を呼んで 5 秒英語で話す  
  **Then:** `AsyncThrowingStream` から `TranscriptionResult` が流れ、少なくとも 1 件の `isFinal == true` 結果が返る
 
- **Given:** `SpeechRecognitionServiceFactory.create()` を iOS 26 環境で呼ぶ  
  **When:** 返り値の型を確認する  
  **Then:** `SpeechAnalyzerService` のインスタンスが返る
 
- **Given:** `SpeechAnalyzerService.stopRecognition()` を呼ぶ  
  **When:** ストリームの結果を確認する  
  **Then:** ストリームが `finish()` で正常終了する（エラーなし）
 
---
 
## Task 3: SpeechRecognitionService の SFSpeechRecognizer フォールバック実装
 
**推定行数:** 130–160 行  
**新規ファイル:** 0（Task 2 で作成した `SpeechRecognitionService.swift` に追記）  
**更新ファイル:** 1  
**依存タスク:** Task 2（プロトコル定義が済んでいること）
 
### 実装内容
 
`SpeechRecognitionService.swift` に `LegacySpeechService` を追加する。
 
- `final class LegacySpeechService: NSObject, SpeechRecognitionServiceProtocol, @unchecked Sendable`
  - `AVAudioEngine` を内部で管理（Task 1 の `RecordingManager` はセッション設定のみ担当）
  - `SFSpeechAudioBufferRecognitionRequest` を生成し `requiresOnDeviceRecognition = true` を必ず設定
  - `shouldReportPartialResults = true` で volatile 結果を取得
  - `recognitionTask(with:resultHandler:)` コールバックを `AsyncThrowingStream` にブリッジ
  - `inputNode.installTap(onBus:bufferSize:format:)` でバッファを認識リクエストに送信
  - `stopRecognition()` で `audioEngine.stop()`, `removeTap`, `endAudio()`, `cancel()` の順に呼ぶ
  - 60秒制限対策: `isFinal == true` を受け取った後、`finalTranscript` に追記してリクエストを再起動するロジック
- `Factory` の `LegacySpeechService` 分岐を完成させる
 
### 完了条件（Given-When-Then）
 
- **Given:** iOS 17 シミュレータで `LegacySpeechService` を初期化した  
  **When:** `startRecognition(locale: Locale(identifier: "ja-JP"))` を呼んで日本語で話す  
  **Then:** `TranscriptionResult` が流れ、`isFinal == false` の volatile 結果と `isFinal == true` の final 結果が交互に返る
 
- **Given:** `LegacySpeechService` の認識リクエストを確認する  
  **When:** `recognitionRequest.requiresOnDeviceRecognition` の値を検証  
  **Then:** `true` であること（オンデバイス強制・プライバシー要件）
 
- **Given:** iOS 17 環境で `SpeechRecognitionServiceFactory.create()` を呼ぶ  
  **When:** 返り値の型を確認する  
  **Then:** `LegacySpeechService` のインスタンスが返る
 
---
 
## Task 4: RecordingViewModel（UI 状態管理 + RecordingManager 統合）
 
**推定行数:** 180–220 行  
**新規ファイル:** 1（`RecordingViewModel.swift` を本実装に置き換え）  
**更新ファイル:** 0  
**依存タスク:** Task 1（権限管理）, Task 2・3（SpeechRecognitionService）
 
### 実装内容
 
`NoteChain/Features/Recording/RecordingViewModel.swift` を完全実装する。
 
- `@MainActor @Observable final class RecordingViewModel`
- 全公開プロパティ（`isRecording`, `finalTranscript`, `volatileTranscript`, `recordingDuration`, `permissionDenied`, `isSaving`, `errorMessage`, `didSaveNote`）
- `checkPermissions() async`: `RecordingManager.checkPermissionStatus()` を呼び、拒否時は `permissionDenied = true`
- `toggleRecording() async`: 録音中なら `stopAndSave()`、そうでなければ権限チェック → 無料枠チェック → `startRecording(locale:)`
- `startRecording(locale:) async`: `recognitionTask = Task { for try await result in speechService.startRecognition ... }`
  - `result.isFinal == true` → `finalTranscript += result.text + " "`, `volatileTranscript = ""`
  - `result.isFinal == false` → `volatileTranscript = result.text`
- `startDurationTimer()`: 1秒ごとに `recordingDuration += 1` を行う `Task` を保持
- `stopAndSave() async`: 仕様書 §SwiftData 保存フロー の手順で実装（キーワード抽出は Task 6 で完成させるため、ここでは空キーワードで保存する仮実装でも可）
- バックグラウンド移行時の自動保存（`didEnterBackgroundNotification` 購読）
- メモリ警告時の自動保存（`didReceiveMemoryWarningNotification` 購読）
 
### 完了条件（Given-When-Then）
 
- **Given:** `MockSpeechService`（isFinal: false/true を交互に返す）を注入した `RecordingViewModel`  
  **When:** `toggleRecording()` を呼ぶ  
  **Then:** `isRecording == true` になり、`volatileTranscript` と `finalTranscript` が更新される
 
- **Given:** 録音中（`isRecording == true`）  
  **When:** `toggleRecording()` を再度呼ぶ  
  **Then:** `isSaving == true` → `didSaveNote == true` の順に状態が遷移する
 
- **Given:** `MockSpeechService` が `AppError.recognitionTaskFailed` をスローする設定  
  **When:** 録音中にエラーが発生する  
  **Then:** `errorMessage` が nil でなくなり、`isRecording == false` になる
 
---
 
## Task 5: RecordingView（UI + ViewModel バインディング）
 
**推定行数:** 200–250 行  
**新規ファイル:** 1（`RecordingView.swift` を本実装に置き換え）  
**更新ファイル:** 0  
**依存タスク:** Task 4（ViewModel が完成していること）
 
### 実装内容
 
`NoteChain/Features/Recording/RecordingView.swift` を完全実装する。
 
**レイアウト構造:**
```
RecordingView
  VStack
    ├── TranscriptDisplayArea     # volatileTranscript（薄紫）+ finalTranscript（黒）
    ├── RecordingTimerView        # "MM:SS" 形式で recordingDuration を表示
    ├── RecordButton              # 録音中はSTOPアイコン、停止中はマイクアイコン
    │     └── タップ → Task { await viewModel.toggleRecording() }
    └── PermissionDeniedView      # permissionDenied == true の時のみ表示
          └── [設定を開く] ボタン
 
.task { await viewModel.checkPermissions() }
.overlay { if viewModel.isSaving { LoadingOverlay(message: "saving") } }
.alert("error_title", isPresented: ...) { ... } // errorMessage がある場合
```
 
- `TranscriptDisplayArea`: `Text(viewModel.finalTranscript)` + `Text(viewModel.volatileTranscript).foregroundStyle(.purple.opacity(0.5))`
- `RecordButton`: `isRecording` に応じてアイコンと色を切り替え（録音中: 赤い停止ボタン）
- `.animation(.easeInOut, value: viewModel.isRecording)` でボタン遷移をアニメーション
- `#Preview` にて `MockSpeechService` 注入済みの ViewModel でプレビューを実装
 
### 完了条件（Given-When-Then）
 
- **Given:** RecordingView を iOS シミュレータで表示した  
  **When:** マイク権限が拒否状態の場合  
  **Then:** `PermissionDeniedView` が表示され、他の UI 要素はグレーアウトされる
 
- **Given:** `viewModel.isSaving == true`  
  **When:** RecordingView を表示する  
  **Then:** `LoadingOverlay` が全体を覆って表示される
 
- **Given:** `viewModel.volatileTranscript = "これはテストです"`  
  **When:** RecordingView を表示する  
  **Then:** テキストが `Color.purple.opacity(0.5)` の色で表示される
 
---
 
## Task 6: 録音完了 → Note 保存 → KeywordExtractor 連携
 
**推定行数:** 120–150 行（`RecordingViewModel.swift` の `stopAndSave` を完成させる + `KeywordExtractor` の呼び出し統合）  
**新規ファイル:** 0  
**更新ファイル:** 2（`RecordingViewModel.swift`, `KeywordExtractor.swift`）  
**依存タスク:** Task 4（ViewModel 基盤）、`Features/Keywords/KeywordExtractor` が実装済みであること
 
### 実装内容
 
1. **`RecordingViewModel.stopAndSave()` の完成:**
   - `let keywords = await keywordExtractor.extractAsync(from: combinedText, maxKeywords: 5)`
   - `Note` を `keywords` と `keywordConfidences` 付きで初期化
   - `modelContext.insert(note)` + `try modelContext.save()`
   - 空テキスト時は `AppError.emptyTranscriptForExtraction` を `errorMessage` にセット
   - 容量不足（`swiftDataSaveFailed`）時はテキストをメモリ保持、エラーバナー表示
 
2. **`KeywordExtractor.extractAsync` の確認:**
   - `Task.detached(priority: .userInitiated)` でバックグラウンド処理することを確認
   - 抽出結果が `[(keyword: String, confidence: Double)]` 型で返ることを確認
 
### 完了条件（Given-When-Then）
 
- **Given:** `finalTranscript = "Marketing meeting about Q2 planning"`  
  **When:** `stopAndSave()` を呼ぶ  
  **Then:** SwiftData に `Note` が 1 件挿入され、`note.keywords` が空でなく、`note.duration > 0` である
 
- **Given:** `finalTranscript = ""` かつ `volatileTranscript = ""`  
  **When:** `stopAndSave()` を呼ぶ  
  **Then:** Note が保存されず、`errorMessage == AppError.emptyTranscriptForExtraction.errorDescription`
 
- **Given:** `KeywordExtractor` が "meeting", "marketing", "planning" を返す  
  **When:** `stopAndSave()` が完了する  
  **Then:** `note.keywords == ["meeting", "marketing", "planning"]` であり、各 `keywordConfidences` が 0.0–1.0 の範囲
 
---
 
## Task 7: RecordingViewModel のユニットテスト
 
**推定行数:** 180–220 行  
**新規ファイル:** 1（`RecordingViewModelTests.swift`）  
**更新ファイル:** 0  
**依存タスク:** Task 4・6（ViewModel 完成後）
 
### 実装内容
 
`NoteChainTests/Features/Recording/RecordingViewModelTests.swift`
 
**テストスイート構成:**
 
```swift
@Suite("RecordingViewModel Tests")
struct RecordingViewModelTests {
    // セットアップ: InMemory ModelContainer + MockSpeechService + MockKeywordExtractor
 
    @Test("Given: 権限あり / When: toggleRecording() / Then: isRecording = true")
    @Test("Given: 録音中 / When: toggleRecording() / Then: stopAndSave() が呼ばれ didSaveNote = true")
    @Test("Given: 権限なし / When: toggleRecording() / Then: permissionDenied = true")
    @Test("Given: 空テキスト / When: stopAndSave() / Then: Note 未保存 + errorMessage セット")
    @Test("Given: 有効テキスト / When: stopAndSave() / Then: Note 保存 + keywords 設定")
    @Test("Given: MockService がエラーをスロー / When: 録音中 / Then: errorMessage セット + isRecording = false")
    @Test("Given: isFinal: false の結果 / When: 受信 / Then: volatileTranscript 更新")
    @Test("Given: isFinal: true の結果 / When: 受信 / Then: finalTranscript 追記 + volatileTranscript クリア")
    @Test("Given: recordingDuration / When: 3秒経過 / Then: duration >= 3")
    @Test("Given: 無料枠上限（週3件）+ 未サブスク / When: toggleRecording() / Then: showPaywall = true")
}
```
 
**モック定義（同ファイルに含める）:**
- `MockSpeechService: SpeechRecognitionServiceProtocol`（設定可能なテスト用シーケンスを返す）
- `MockKeywordExtractor: KeywordExtractorProtocol`（固定値を返す）
- InMemory `ModelContainer` のセットアップヘルパー
 
### 完了条件（Given-When-Then）
 
- **Given:** `swift test` を実行した  
  **When:** `RecordingViewModelTests` スイートが走る  
  **Then:** 全 10 テストが PASS し、失敗が 0 件である
 
- **Given:** テストが実行される  
  **When:** 実際の `AVAudioEngine` や `SFSpeechRecognizer` が呼ばれる  
  **Then:** 一切呼ばれない（すべてモック経由）
 
---
 
## Task 8: RecordingView の UIテスト（録音フロー E2E）
 
**推定行数:** 150–200 行  
**新規ファイル:** 1（`RecordingFlowUITests.swift`）  
**更新ファイル:** 0  
**依存タスク:** Task 5・6（View と保存フローが完成後）
 
### 実装内容
 
`NoteChainUITests/RecordingFlowUITests.swift`
 
**テストケース:**
 
```swift
@Suite("Recording Flow E2E")
final class RecordingFlowUITests: XCTestCase {
    // XCUIApplication でアプリ起動（ launchArguments に "--ui-testing" フラグ）
 
    func test_録音ボタンタップ_録音開始() // マイクボタンが存在し、タップ後に停止ボタンへ変化
    func test_停止ボタンタップ_保存完了_ノート一覧遷移() // 停止後にNotesList画面に遷移
    func test_権限拒否状態_PermissionDeniedView表示() // launchArgument でシミュレート
    func test_保存中_LoadingOverlay表示() // isSaving 状態中のオーバーレイ確認
    func test_エラー発生_アラート表示() // エラー時のアラートを確認
}
```
 
**注意点:**
- UIテストではマイク実権限は使わない。`--ui-testing` フラグで `MockSpeechService` に切り替えるアプリ側のフックを `NoteChainApp.swift` に追加する
- `XCUIElement.waitForExistence(timeout: 5)` を使って非同期 UI の更新を待機
 
### 完了条件（Given-When-Then）
 
- **Given:** UIテストを実行した  
  **When:** `RecordingFlowUITests` が走る  
  **Then:** 全 5 テストケースが PASS する
 
- **Given:** 録音停止テストが実行された  
  **When:** 停止ボタンをタップした後  
  **Then:** NotesList 画面の `navigationTitle` または最低1件のノートセルが画面上に表示される
 
---
 
## タスク一覧サマリー
 
| # | タスク名 | 推定行数 | 依存 | 新規ファイル数 |
|---|---------|---------|------|--------------|
| 1 | RecordingManager 基盤 | 120–150 | なし | 1 |
| 2 | SpeechAnalyzerService 実装 | 120–150 | Task 1 | 1 |
| 3 | LegacySpeechService フォールバック | 130–160 | Task 2 | 0（追記） |
| 4 | RecordingViewModel | 180–220 | Task 1, 2, 3 | 1 |
| 5 | RecordingView | 200–250 | Task 4 | 1 |
| 6 | Note保存・Keyword連携 | 120–150 | Task 4 + Keywords | 0（更新） |
| 7 | RecordingViewModel ユニットテスト | 180–220 | Task 4, 6 | 1 |
| 8 | RecordingView UIテスト E2E | 150–200 | Task 5, 6 | 1 |
 
**合計推定行数:** 1,200–1,300 行
 
---
 
**ドキュメントオーナー:** kiki-her  
**最終更新:** 2026-04-02
