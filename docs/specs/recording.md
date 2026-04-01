# 機能仕様書: 音声録音 & リアルタイム文字起こし
 
**機能ID:** FEAT-001  
**バージョン:** 1.0  
**作成日:** 2026-04-02  
**ステータス:** 実装準備完了  
**担当モジュール:** `NoteChain/Features/Recording/`  
**依拠ドキュメント:** `docs/PRD.md` §機能1, `docs/ARCHITECTURE.md` §2.1
 
---
 
## 概要
 
AVAudioEngine でマイク入力を取得し、`SpeechRecognitionServiceProtocol` 経由で
`SpeechAnalyzerService`（iOS 26+）または `LegacySpeechService`（iOS 17–25）に音声を渡す。
volatile（途中経過）と final（確定）の2段階でリアルタイムにテキストを表示し、
録音停止後は `KeywordExtractor` でキーワード抽出を行って SwiftData に `Note` として保存する。
 
---
 
## ユーザーストーリー
 
### US-001
> 「ユーザーとして、録音ボタンをタップして音声メモを開始し、リアルタイムで文字起こしを確認したい」
 
**優先度:** Must Have  
**対象ユーザー:** 全ユーザー  
**前提条件:** アプリのインストール済み、マイク権限付与済み
 
### US-002
> 「ユーザーとして、停止ボタンをタップして録音を終了し、文字起こし結果をノートとして保存したい」
 
**優先度:** Must Have  
**対象ユーザー:** 全ユーザー  
**前提条件:** US-001 が実行された状態（録音中）
 
### US-003
> 「ユーザーとして、設定で選択した言語で文字起こしが行われることを期待する」
 
**優先度:** Must Have  
**対象ユーザー:** 多言語利用者（日本語・スペイン語話者）  
**前提条件:** 設定画面で録音言語を変更済み
 
---
 
## 受け入れ基準（Given-When-Then）
 
### AC-001: 正常録音開始
- **Given:** アプリがマイク権限と音声認識権限の両方を持っている  
- **When:** 録音ボタンをタップする  
- **Then:** 録音が開始され、500ms 以内に volatile テキストが薄紫色（`Color.purple.opacity(0.5)`）でリアルタイム表示される
 
### AC-002: 録音停止・保存
- **Given:** 録音中（`isRecording == true`）  
- **When:** 停止ボタンをタップする  
- **Then:** 最終テキストが SwiftData に `Note` として保存され、`didSaveNote == true` になり、NotesList に遷移する
 
### AC-003: マイク権限リクエスト
- **Given:** マイク権限が未設定（`.notDetermined`）  
- **When:** 録音ボタンをタップする  
- **Then:** iOS 標準の権限リクエストダイアログが `AVAudioApplication.requestRecordPermission()` 経由で表示される
 
### AC-004: マイク権限拒否後の UI
- **Given:** マイク権限を拒否した（`.denied`）  
- **When:** 設定画面に遷移するボタンを表示（`PermissionDeniedView`）  
- **Then:** ユーザーが [設定を開く] をタップすると `UIApplication.openSettings()` でiOS設定が開き、権限変更が可能になる
 
### AC-005: 電話着信による中断
- **Given:** 録音中に電話着信が発生した  
- **When:** AVAudioSession の `interruptionNotification` が `.began` で通知される  
- **Then:** 録音が一時停止し、`RecordingManager.isAudioSessionActive == false` になる。通知が `.ended` になった後、ユーザーが録音を再開可能な状態（UI が再開ボタンを表示）になる
 
### AC-006: 多言語対応
- **Given:** 設定で録音言語を「日本語（ja-JP）」に選択済み  
- **When:** 日本語で話す  
- **Then:** `SpeechRecognitionService.startRecognition(locale: Locale(identifier: "ja-JP"))` が呼ばれ、日本語で文字起こしされる
 
### AC-007: SpeechAnalyzer 利用（iOS 26+）
- **Given:** iOS 26 以上のデバイス/シミュレータ  
- **When:** 録音を開始する  
- **Then:** `SpeechRecognitionServiceFactory.create()` が `SpeechAnalyzerService` を返し、`SpeechAnalyzer` が使用される（ログで確認可能）
 
### AC-008: SFSpeechRecognizer フォールバック（iOS 17–25）
- **Given:** iOS 17.0–25.x のデバイス/シミュレータ  
- **When:** 録音を開始する  
- **Then:** `SpeechRecognitionServiceFactory.create()` が `LegacySpeechService` を返し、`SFSpeechRecognizer` + `requiresOnDeviceRecognition = true` が使用される
 
---
 
## 技術設計
 
### アーキテクチャ概要
 
```
RecordingView
    └── @State RecordingViewModel  (@MainActor @Observable)
            ├── RecordingManager           (AVAudioSession ライフサイクル)
            ├── SpeechRecognitionService   (プロトコル DI)
            │       ├── SpeechAnalyzerService      (iOS 26+)
            │       └── LegacySpeechService        (iOS 17–25)
            ├── KeywordExtractorProtocol   (保存前に呼び出し)
            └── ModelContext               (SwiftData 保存)
```
 
### SpeechRecognitionServiceProtocol
 
```swift
protocol SpeechRecognitionServiceProtocol: Sendable {
    func startRecognition(locale: Locale) -> AsyncThrowingStream<TranscriptionResult, Error>
    func stopRecognition() async
    var isAvailable: Bool { get async }
}
 
struct TranscriptionResult: Sendable, Equatable {
    let text: String
    let isFinal: Bool       // false = volatile（薄紫）/ true = final（黒）
    let confidence: Double? // SpeechAnalyzer: nil / SFSpeechRecognizer: 0.0–1.0
    let timestamp: Date
}
```
 
### RecordingManager（AVAudioEngine ライフサイクル管理）
 
責務: AVAudioSession のカテゴリ設定・割り込み処理・セッション有効/無効化
 
```swift
@Observable
final class RecordingManager: NSObject, Sendable {
    var isAudioSessionActive: Bool = false
 
    func configureAudioSession() throws
    // .record カテゴリ, .measurement モード, .duckOthers オプション
    // setActive(true, options: .notifyOthersOnDeactivation)
 
    func handleAudioSessionInterruption(_ notification: Notification) async
    // .began → isAudioSessionActive = false（録音一時停止）
    // .ended + shouldResume → isAudioSessionActive = true（再開可能通知）
 
    func deactivateAudioSession()
    // setActive(false, options: .notifyOthersOnDeactivation)
}
```
 
### RecordingViewModel（UI 状態管理）
 
```swift
@MainActor
@Observable
final class RecordingViewModel {
    // 公開プロパティ
    var isRecording: Bool = false
    var finalTranscript: String = ""       // 黒色で表示（確定済み）
    var volatileTranscript: String = ""    // 薄紫色で表示（途中経過）
    var recordingDuration: TimeInterval = 0
    var permissionDenied: Bool = false
    var isSaving: Bool = false
    var errorMessage: String? = nil
    var didSaveNote: Bool = false          // 保存完了 → NotesList 遷移トリガー
 
    // 依存注入
    init(
        speechService: any SpeechRecognitionServiceProtocol = SpeechRecognitionServiceFactory.create(),
        keywordExtractor: any KeywordExtractorProtocol = NLTaggerKeywordExtractor(),
        modelContext: ModelContext
    )
 
    // 公開メソッド
    func checkPermissions() async
    func toggleRecording() async     // 開始/停止トグル
    func stopAndSave() async         // 停止 → キーワード抽出 → SwiftData 保存
}
```
 
### volatile / final の区別表示
 
| 状態 | テキスト色 | 対応プロパティ |
|------|-----------|--------------|
| 途中経過（isFinal: false） | `Color.purple.opacity(0.5)` | `volatileTranscript` |
| 確定済み（isFinal: true） | `.primary`（黒/白） | `finalTranscript` |
 
保存時は `finalTranscript + volatileTranscript` を結合して `Note.transcript` に格納する。
 
### SwiftData 保存フロー
 
```
stopAndSave() 呼び出し
    1. isSaving = true
    2. speechService.stopRecognition()
    3. durationTimer?.cancel()
    4. let combinedText = finalTranscript + volatileTranscript
    5. let keywords = await keywordExtractor.extractAsync(from: combinedText, maxKeywords: 5)
    6. let note = Note(
           transcript: combinedText,
           keywords: keywords.map(\.keyword),
           keywordConfidences: Dictionary(uniqueKeysWithValues: keywords),
           duration: recordingDuration,
           languageCode: currentLocale.identifier
       )
    7. modelContext.insert(note)
    8. try modelContext.save()
    9. isSaving = false
   10. didSaveNote = true
```
 
---
 
## エッジケース
 
| # | ケース | 対処方法 |
|---|--------|---------|
| EC-001 | **端末の空き容量不足** | `modelContext.save()` が失敗 → `AppError.swiftDataSaveFailed` を `errorMessage` にセット。テキストはメモリ上に保持し、ユーザーに警告バナーを表示 |
| EC-002 | **1分以上の長時間録音** | `SpeechAnalyzer` は長時間音声に対応。`LegacySpeechService` は `SFSpeechAudioBufferRecognitionRequest` の60秒制限に達する前に自動で新しいリクエストを作成（リクエスト再起動パターン）。`finalTranscript` に順次追記 |
| EC-003 | **無音が30秒以上続く** | `durationTimer` は継続カウント。`SFSpeechRecognizer` は無音タイムアウトでストリームを終了する場合があるため、`recognitionTask` の終了を検知して自動で再起動を試みる。UI には「無音中...」インジケーターを表示 |
| EC-004 | **バックグラウンド移行** | `AVAudioSession` は `Background Modes` なしでは録音継続不可のため、`UIApplication.didEnterBackgroundNotification` を受けて `stopAndSave()` を自動呼び出し。保存後に `didSaveNote = true` |
| EC-005 | **複数言語が混在する発話** | `locale` は録音開始時点の設定言語を使用。混在部分の精度は低下するが処理は継続。将来的に「自動検出（auto）」設定で `NLLanguageRecognizer` による動的ロケール切り替えを実装予定（v1.1） |
| EC-006 | **Bluetooth マイク接続中** | `AVAudioEngine` は接続中の入力デバイスを自動選択。Bluetooth マイクが優先される。`AVAudioSession.routeChangeNotification` を監視し、ルート変更時にエンジンを再設定 |
| EC-007 | **機内モード中（SFSpeechRecognizer のオンデバイスモード）** | `requiresOnDeviceRecognition = true` により、機内モードでも `LegacySpeechService` は動作。ただし、オンデバイスモデルが未ダウンロードの場合は `AppError.speechRecognitionUnavailable` を表示し、Wi-Fi 接続を促すバナーを表示 |
| EC-008 | **iOS 17 デバイスで SpeechAnalyzer 非対応時のフォールバック** | `SpeechRecognitionServiceFactory.create()` が `#available(iOS 26, *)` チェックで `LegacySpeechService` を返す。ユーザーには透過的で、同一 UI・同一フロー |
| EC-009 | **録音中にメモリ警告** | `UIApplication.didReceiveMemoryWarningNotification` を受けて `stopAndSave()` を呼び出し、現時点のテキストを保存してリソースを解放 |
| EC-010 | **空のテキストで停止** | `combinedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty` の場合は Note を保存せず、`errorMessage = AppError.emptyTranscriptForExtraction.errorDescription` を表示 |
 
---
 
## 必要な権限
 
| 権限 | Info.plist キー | 説明文（ja） |
|------|----------------|------------|
| マイク | `NSMicrophoneUsageDescription` | 「音声メモを録音するためにマイクを使用します」 |
| 音声認識 | `NSSpeechRecognitionUsageDescription` | 「音声をテキストに変換するために音声認識を使用します」 |
 
---
 
## 依存関係
 
| 依存先 | 用途 |
|--------|------|
| `Shared/Services/SpeechRecognitionService` | 音声認識（DI） |
| `Features/Keywords/KeywordExtractor` | 保存前キーワード抽出 |
| `Shared/Models/Note` | SwiftData 保存 |
| `Shared/Models/AppError` | エラー表現 |
| `Shared/Navigation/Router` | 保存後 NoteDetail 遷移 |
| `Features/Subscription/SubscriptionManager` | 無料枠チェック（週3件） |
| `Features/Settings/SettingsViewModel` | `speechLocale` 取得 |
 
---
 
## 関連ファイル
 
```
NoteChain/Features/Recording/
├── RecordingView.swift         # メイン録音UI
├── RecordingViewModel.swift    # @MainActor @Observable 状態管理
├── RecordingManager.swift      # AVAudioSession ライフサイクル
└── README.md
 
NoteChain/Shared/Services/
└── SpeechRecognitionService.swift  # プロトコル + 2実装 + Factory
 
NoteChainTests/Features/Recording/
└── RecordingViewModelTests.swift
 
NoteChainUITests/
└── RecordingFlowUITests.swift
```
 
---
 
**ドキュメントオーナー:** kiki-her  
**最終更新:** 2026-04-02  
**次回レビュー:** Task 1 実装開始前
