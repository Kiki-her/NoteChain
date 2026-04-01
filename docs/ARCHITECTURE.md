# NoteChain — 技術設計書（ARCHITECTURE.md）

**バージョン:** 1.0  
**日付:** 2026-04-01  
**ステータス:** AI 駆動開発 実装準備完了  
**対象:** Claude Code + XcodeBuildMCP による自律実装  
**依拠 PRD:** `@docs/PRD.md`

---

## 目次

1. [ディレクトリ構造（完全版）](#1-ディレクトリ構造完全版)
2. [Featureモジュール設計](#2-featureモジュール設計)
   - 2.1 [Recording](#21-recording-音声録音--リアルタイム文字起こし)
   - 2.2 [Keywords](#22-keywords-キーワード抽出)
   - 2.3 [NotesList](#23-noteslist-ノート一覧--検索)
   - 2.4 [Settings / i18n](#24-settings--i18n-設定--多言語)
   - 2.5 [Subscription](#25-subscription-サブスクリプション)
   - 2.6 [Onboarding](#26-onboarding-オンボーディング)
3. [Shared レイヤー設計](#3-shared-レイヤー設計)
   - 3.1 [SpeechRecognitionService](#31-speechrecognitionservice)
   - 3.2 [KeywordExtractor](#32-keywordextractor)
   - 3.3 [Router](#33-router)
   - 3.4 [Note @Model](#34-note-model)
   - 3.5 [AppError](#35-apperror)
4. [画面遷移図](#4-画面遷移図)
5. [.claude/rules/ ルールファイル設計](#5-clauderules-ルールファイル設計)
6. [開発フェーズ（6週間）](#6-開発フェーズ6週間)
7. [依存関係マトリクス](#7-依存関係マトリクス)
8. [Swift 6 Concurrency 設計方針](#8-swift-6-concurrency-設計方針)

---

## 1. ディレクトリ構造（完全版）

```
NoteChain/
├── CLAUDE.md                              # AI駆動開発メイン指示書（200行以内）
├── AGENTS.md                              # 他AIツール互換（CLAUDE.mdをインポート）
├── .claude/
│   ├── CLAUDE.md                          # .claudeディレクトリ概要
│   ├── rules/
│   │   ├── general.md                     # 全体ルール（常時ロード）
│   │   ├── security.md                    # セキュリティ禁則事項（常時ロード）
│   │   ├── swift-style.md                 # Swift 6 / Concurrency 規約
│   │   ├── swiftui.md                     # SwiftUI固有パターン
│   │   ├── swiftdata.md                   # SwiftData / @Model 規約
│   │   ├── testing.md                     # Swift Testing 規約
│   │   └── subscription.md               # StoreKit 2 規約
│   ├── skills/
│   │   ├── implement-feature/
│   │   │   └── SKILL.md
│   │   ├── code-review/
│   │   │   └── SKILL.md
│   │   └── test-generator/
│   │       └── SKILL.md
│   ├── commands/
│   │   ├── build.md
│   │   ├── test.md
│   │   ├── generate-spec.md
│   │   ├── generate-tasks.md
│   │   └── implement-feature.md
│   └── settings.json
├── .mcp.json                              # XcodeBuildMCP 設定
├── docs/
│   ├── PRD.md
│   ├── ARCHITECTURE.md                    # 本ドキュメント
│   └── specs/
│       ├── template.md
│       ├── recording.md
│       ├── keywords.md
│       ├── notes-list.md
│       ├── settings.md
│       └── subscription.md
├── NoteChain/
│   ├── App/
│   │   ├── NoteChainApp.swift             # @main エントリポイント
│   │   ├── ContentView.swift              # ルート TabView + Router
│   │   └── AppState.swift                 # アプリ全体の状態 (@Observable)
│   ├── Features/
│   │   ├── Recording/
│   │   │   ├── RecordingView.swift        # 録音 UI（マイクボタン + テキスト表示）
│   │   │   ├── RecordingViewModel.swift   # 録音状態管理 (@MainActor @Observable)
│   │   │   ├── RecordingManager.swift     # AVAudioEngine ライフサイクル
│   │   │   └── README.md
│   │   ├── Keywords/
│   │   │   ├── KeywordExtractor.swift     # NLTagger実装 + プロトコル
│   │   │   ├── KeywordBadgeView.swift     # バッジ表示コンポーネント
│   │   │   └── README.md
│   │   ├── NotesList/
│   │   │   ├── NotesListView.swift        # ノート一覧 + 検索バー
│   │   │   ├── NotesListViewModel.swift   # 検索/ソート状態管理
│   │   │   ├── NoteRowView.swift          # 一覧行コンポーネント
│   │   │   ├── NoteDetailView.swift       # ノート詳細 + 編集
│   │   │   ├── NoteDetailViewModel.swift  # 詳細画面状態管理
│   │   │   └── README.md
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift         # 設定ルート画面
│   │   │   ├── SettingsViewModel.swift    # 設定状態管理 (@AppStorage)
│   │   │   ├── LanguagePickerView.swift   # 言語選択ピッカー
│   │   │   └── README.md
│   │   ├── Subscription/
│   │   │   ├── PaywallView.swift          # ペイウォール画面
│   │   │   ├── SubscriptionManager.swift  # StoreKit 2 管理 (@MainActor @Observable)
│   │   │   ├── SubscriptionBadgeView.swift # Pro バッジ
│   │   │   └── README.md
│   │   └── Onboarding/
│   │       ├── OnboardingView.swift       # 初回起動フロー（権限→言語→ペイウォール）
│   │       ├── OnboardingViewModel.swift  # オンボーディング状態管理
│   │       └── README.md
│   ├── Shared/
│   │   ├── Models/
│   │   │   ├── Note.swift                 # @Model SwiftData エンティティ
│   │   │   └── AppError.swift             # アプリ共通エラー型
│   │   ├── Navigation/
│   │   │   └── Router.swift               # NavigationStack + Route enum
│   │   ├── Services/
│   │   │   └── SpeechRecognitionService.swift  # プロトコル + 2実装 + Factory
│   │   ├── Extensions/
│   │   │   ├── Date+Formatting.swift      # 相対時刻・フォーマット拡張
│   │   │   └── String+Localized.swift     # ローカライズ補助拡張
│   │   └── Components/
│   │       ├── LoadingOverlay.swift       # ローディングオーバーレイ
│   │       ├── EmptyStateView.swift       # 空状態表示
│   │       └── PermissionDeniedView.swift # 権限拒否状態表示
│   └── Resources/
│       ├── Localizable.xcstrings          # 多言語文字列（en, ja, es）
│       └── Assets.xcassets/
├── NoteChainTests/
│   ├── Features/
│   │   ├── Recording/
│   │   │   └── RecordingViewModelTests.swift
│   │   ├── Keywords/
│   │   │   └── KeywordExtractorTests.swift
│   │   ├── NotesList/
│   │   │   └── NotesListViewModelTests.swift
│   │   └── Subscription/
│   │       └── SubscriptionManagerTests.swift
│   └── Shared/
│       └── Models/
│           └── NoteTests.swift
└── NoteChainUITests/
    ├── RecordingFlowUITests.swift
    ├── PaywallUITests.swift
    └── LanguageSwitchUITests.swift
```

---

## 2. Featureモジュール設計

### 2.1 Recording — 音声録音 & リアルタイム文字起こし

**責務:**  
AVAudioEngine を使いマイク入力を取得し、SpeechRecognitionService を通じてリアルタイムで音声→テキスト変換を行い、volatile / final 結果を即時 UI に反映する。録音完了時は Note を SwiftData に保存し、キーワード抽出をトリガーする。

#### View 一覧

| ファイル | 役割 |
|---------|------|
| `RecordingView.swift` | メイン録音画面。マイクボタン（タップで録音開始/停止）、リアルタイムテキスト表示エリア（volatile=薄紫 / final=黒）、録音時間インジケーター、権限エラーバナー、保存中ローディングを含む |

```swift
// RecordingView の主要なUI構造
struct RecordingView: View {
    @State private var viewModel = RecordingViewModel()

    var body: some View {
        VStack(spacing: 24) {
            // リアルタイム文字起こし表示
            TranscriptDisplayArea(
                finalText: viewModel.finalTranscript,
                volatileText: viewModel.volatileTranscript
            )

            // 録音時間
            RecordingTimerView(duration: viewModel.recordingDuration)

            // 録音ボタン
            RecordButton(
                isRecording: viewModel.isRecording,
                action: { Task { await viewModel.toggleRecording() } }
            )

            // 権限拒否バナー
            if viewModel.permissionDenied {
                PermissionDeniedView(service: .microphone)
            }
        }
        .task { await viewModel.checkPermissions() }
        .overlay { if viewModel.isSaving { LoadingOverlay(message: "saving") } }
    }
}
```

#### ViewModel 設計

```swift
// NoteChain/Features/Recording/RecordingViewModel.swift
import Foundation
import SwiftData

@MainActor
@Observable
final class RecordingViewModel {
    // --- 公開プロパティ ---
    var isRecording: Bool = false
    var finalTranscript: String = ""
    var volatileTranscript: String = ""
    var recordingDuration: TimeInterval = 0
    var permissionDenied: Bool = false
    var isSaving: Bool = false
    var errorMessage: String? = nil
    var didSaveNote: Bool = false  // 保存完了通知（親Viewへ）

    // --- 依存注入 ---
    private let speechService: any SpeechRecognitionServiceProtocol
    private let keywordExtractor: any KeywordExtractorProtocol
    private let modelContext: ModelContext

    // --- 内部状態 ---
    private var recognitionTask: Task<Void, Never>?
    private var durationTimer: Task<Void, Never>?
    private var recordingStartTime: Date?

    init(
        speechService: any SpeechRecognitionServiceProtocol = SpeechRecognitionServiceFactory.create(),
        keywordExtractor: any KeywordExtractorProtocol = NLTaggerKeywordExtractor(),
        modelContext: ModelContext
    ) {
        self.speechService = speechService
        self.keywordExtractor = keywordExtractor
        self.modelContext = modelContext
    }

    // --- 公開メソッド ---
    func checkPermissions() async { ... }
    func toggleRecording() async { ... }
    func stopAndSave() async { ... }

    // --- 内部メソッド ---
    private func startRecording(locale: Locale) async { ... }
    private func startDurationTimer() { ... }
    private func saveNote() async throws { ... }
}
```

**公開プロパティ一覧:**

| プロパティ | 型 | 説明 |
|-----------|-----|------|
| `isRecording` | `Bool` | 録音中フラグ |
| `finalTranscript` | `String` | 確定済みテキスト（黒表示用） |
| `volatileTranscript` | `String` | 暫定テキスト（薄紫表示用） |
| `recordingDuration` | `TimeInterval` | 経過秒数 |
| `permissionDenied` | `Bool` | マイク権限拒否状態 |
| `isSaving` | `Bool` | 保存処理中フラグ（ローディング表示） |
| `errorMessage` | `String?` | エラーメッセージ |
| `didSaveNote` | `Bool` | Note 保存完了フラグ（NotesList遷移トリガー） |

**公開メソッド一覧:**

| メソッド | シグネチャ | 説明 |
|---------|-----------|------|
| `checkPermissions` | `() async` | マイク・音声認識権限を確認、拒否時は `permissionDenied = true` |
| `toggleRecording` | `() async` | 録音開始/停止トグル |
| `stopAndSave` | `() async` | 録音停止 → キーワード抽出 → SwiftData 保存 |

#### RecordingManager 設計

```swift
// NoteChain/Features/Recording/RecordingManager.swift
// AVAudioEngine の低レベルライフサイクルを担当（録音セッション管理）
import AVFoundation

@Observable
final class RecordingManager: NSObject, Sendable {
    var isAudioSessionActive: Bool = false

    func configureAudioSession() throws { ... }
    func handleAudioSessionInterruption(_ notification: Notification) async { ... }
    func deactivateAudioSession() { ... }
}
```

#### 依存するモジュール・サービス

| 依存先 | 用途 |
|--------|------|
| `Shared/Services/SpeechRecognitionService` | 音声認識サービスプロトコル（DI） |
| `Features/Keywords/KeywordExtractor` | 保存時にキーワード抽出 |
| `Shared/Models/Note` | SwiftData への保存 |
| `Shared/Models/AppError` | エラー表示 |
| `Shared/Navigation/Router` | 保存後にノート詳細へ遷移 |
| `Features/Subscription/SubscriptionManager` | 無料枠チェック |

---

### 2.2 Keywords — キーワード抽出

**責務:**  
NaturalLanguage フレームワーク（NLTagger）を用いてテキストから名詞・固有名詞を抽出し、信頼度スコア付きのキーワードリストを返す。また、キーワードをバッジとして表示する再利用可能な UI コンポーネントを提供する。

#### View 一覧

| ファイル | 役割 |
|---------|------|
| `KeywordBadgeView.swift` | 個別キーワードをカプセル形バッジで表示。タップでキーワードフィルタを発火するコールバックを受け取る。削除ボタン付き（詳細画面のみ表示） |

```swift
// KeywordBadgeView.swift
struct KeywordBadgeView: View {
    let keyword: String
    let confidence: Double?
    var isEditable: Bool = false
    var onTap: ((String) -> Void)? = nil
    var onDelete: ((String) -> Void)? = nil

    var body: some View {
        HStack(spacing: 4) {
            Text("#\(keyword)")
                .font(.caption.bold())
                .foregroundStyle(.purple)
            if isEditable {
                Button { onDelete?(keyword) } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption2)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.purple.opacity(0.12), in: Capsule())
        .onTapGesture { onTap?(keyword) }
    }
}
```

#### KeywordExtractor プロトコルと実装

```swift
// NoteChain/Features/Keywords/KeywordExtractor.swift
import NaturalLanguage

// MARK: - Protocol（v1.1 Core ML 実装への差し替え対応）
protocol KeywordExtractorProtocol: Sendable {
    func extract(from text: String, maxKeywords: Int) -> [(keyword: String, confidence: Double)]
    func extractAsync(from text: String, maxKeywords: Int) async -> [(keyword: String, confidence: Double)]
}

// MARK: - Default implementation for async
extension KeywordExtractorProtocol {
    func extractAsync(from text: String, maxKeywords: Int = 5) async -> [(keyword: String, confidence: Double)] {
        // CPU-bound 処理をバックグラウンドに退避
        await Task.detached(priority: .userInitiated) {
            self.extract(from: text, maxKeywords: maxKeywords)
        }.value
    }
}

// MARK: - NLTagger 実装（MVP）
final class NLTaggerKeywordExtractor: KeywordExtractorProtocol {
    // PRD記載の実装（名詞・固有名詞抽出 + 頻度スコアリング）
    func extract(from text: String, maxKeywords: Int = 5) -> [(keyword: String, confidence: Double)] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        let language = recognizer.dominantLanguage ?? .english

        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
        tagger.string = text
        tagger.setLanguage(language, range: text.startIndex..<text.endIndex)

        var wordFrequency: [String: Int] = [:]
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]

        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: options
        ) { tag, tokenRange in
            guard let tag else { return true }
            let allowedTags: [NLTag] = [.noun, .personalName, .placeName, .organizationName]
            if allowedTags.contains(tag) {
                let word = String(text[tokenRange]).lowercased()
                if word.count > 1 && !Self.stopWords.contains(word) {
                    wordFrequency[word, default: 0] += 1
                }
            }
            return true
        }

        let maxFreq = Double(wordFrequency.values.max() ?? 1)
        return wordFrequency
            .map { (keyword: $0.key, confidence: Double($0.value) / maxFreq) }
            .sorted { $0.confidence > $1.confidence }
            .prefix(maxKeywords)
            .map { $0 }
    }

    // ストップワード（英語・日本語・スペイン語）
    static let stopWords: Set<String> = [ /* PRD記載のセット */ ]
}

// MARK: - ファクトリ（v1.1以降、Core ML実装に切り替え）
enum KeywordExtractorFactory {
    static func create() -> any KeywordExtractorProtocol {
        // v1.1: if coreMLModelExists { return CoreMLKeywordExtractor() }
        return NLTaggerKeywordExtractor()
    }
}
```

#### 依存するモジュール・サービス

| 依存先 | 用途 |
|--------|------|
| `Shared/Models/Note` | キーワードを Note に書き込む |
| NaturalLanguage (system) | NLTagger, NLLanguageRecognizer |

---

### 2.3 NotesList — ノート一覧 & 検索

**責務:**  
SwiftData から Note を取得し、テキスト検索・キーワードフィルタ・ソートを適用して一覧表示する。ノートのタップで詳細画面へ遷移し、スワイプ削除もサポートする。

#### View 一覧

| ファイル | 役割 |
|---------|------|
| `NotesListView.swift` | 検索バー・ソートメニュー・日付セクション区切りを持つメインリスト画面。`@Query` は使わず ViewModel 経由でデータ取得 |
| `NoteRowView.swift` | リスト行コンポーネント。タイトル（transcript先頭50字）・キーワードバッジ・時刻・録音時間を表示 |
| `NoteDetailView.swift` | ノート全文表示・文字起こしインライン編集・キーワード追加/削除・お気に入りトグル |

```swift
// NotesListView の骨格
struct NotesListView: View {
    @State private var viewModel: NotesListViewModel
    @Environment(Router.self) private var router

    var body: some View {
        NavigationStack(path: Bindable(router).notesPath) {
            List {
                ForEach(viewModel.groupedNotes.keys.sorted(by: >), id: \.self) { date in
                    Section(header: Text(date.formatted(.relative(presentation: .named)))) {
                        ForEach(viewModel.groupedNotes[date] ?? []) { note in
                            NoteRowView(note: note)
                                .onTapGesture { router.push(.noteDetail(note.id)) }
                        }
                        .onDelete { viewModel.deleteNotes(at: $0, in: date) }
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "search_notes")
            .toolbar { SortOrderMenu(selection: $viewModel.sortOrder) }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .noteDetail(let id): NoteDetailView(noteID: id)
                default: EmptyView()
                }
            }
        }
    }
}
```

#### ViewModel 設計

```swift
// NoteChain/Features/NotesList/NotesListViewModel.swift
@MainActor
@Observable
final class NotesListViewModel {
    // --- 公開プロパティ ---
    var searchText: String = ""
    var sortOrder: SortOrder = .newestFirst
    var languageFilter: String? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // --- 計算プロパティ ---
    var filteredNotes: [Note] { ... }                        // 検索・フィルタ適用済みリスト
    var groupedNotes: [Date: [Note]] { ... }                 // 日付でセクション分けしたDictionary

    // --- 依存注入 ---
    private let modelContext: ModelContext

    // --- 公開メソッド ---
    func deleteNotes(at offsets: IndexSet, in sectionDate: Date) { ... }
    func toggleFavorite(_ note: Note) { ... }
    func applyKeywordFilter(_ keyword: String) { ... }       // キーワードバッジタップ時
    func clearFilters() { ... }

    enum SortOrder: String, CaseIterable, Identifiable {
        case newestFirst, oldestFirst, longestFirst, mostKeywords
        var id: String { rawValue }
        var localizedLabel: LocalizedStringKey { ... }
        var sortDescriptor: SortDescriptor<Note> { ... }
    }
}
```

**NoteDetailViewModel 設計:**

```swift
@MainActor
@Observable
final class NoteDetailViewModel {
    // --- 公開プロパティ ---
    var note: Note?
    var isEditing: Bool = false
    var editingTranscript: String = ""
    var isExtractingKeywords: Bool = false
    var newKeywordText: String = ""
    var errorMessage: String? = nil

    // --- 依存注入 ---
    private let modelContext: ModelContext
    private let keywordExtractor: any KeywordExtractorProtocol
    private let noteID: UUID

    // --- 公開メソッド ---
    func loadNote() { ... }
    func startEditing() { ... }
    func saveEdit() async { ... }                            // transcript 更新 → キーワード再抽出
    func cancelEdit() { ... }
    func addKeyword(_ keyword: String) { ... }
    func removeKeyword(_ keyword: String) { ... }
    func reExtractKeywords() async { ... }
    func toggleFavorite() { ... }
    func deleteNote() { ... }
}
```

#### 依存するモジュール・サービス

| 依存先 | 用途 |
|--------|------|
| `Shared/Models/Note` | SwiftData フェッチ・削除 |
| `Features/Keywords/KeywordBadgeView` | バッジ表示（NoteRowView, NoteDetailView） |
| `Features/Keywords/KeywordExtractor` | 詳細画面でのキーワード再抽出 |
| `Shared/Navigation/Router` | 詳細画面への push 遷移 |
| `Shared/Components/EmptyStateView` | ノート0件時の空状態 |

---

### 2.4 Settings / i18n — 設定 & 多言語

**責務:**  
録音言語・UI言語の選択と `@AppStorage` への永続化を担う。言語変更を SpeechRecognitionService のロケールに反映する。アプリ全体のローカライズ（en/ja/es）を管理する。

#### View 一覧

| ファイル | 役割 |
|---------|------|
| `SettingsView.swift` | 設定ルート画面。録音言語セクション・UI言語セクション・バージョン情報・サブスクリプションバッジ・プライバシーポリシーリンクを含む |
| `LanguagePickerView.swift` | 録音言語選択ピッカー。フラグ絵文字と言語名のリスト。「自動検出」オプション付き |

```swift
// SettingsView の骨格
struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(SubscriptionManager.self) private var subscriptionManager

    var body: some View {
        NavigationStack {
            Form {
                Section("recording_language_section") {
                    LanguagePickerView(selection: $viewModel.recordingLanguage)
                }
                Section("ui_language_section") {
                    Picker("ui_language_label", selection: $viewModel.uiLanguage) {
                        ForEach(SettingsViewModel.supportedUILanguages, id: \.code) { lang in
                            Text(lang.name).tag(lang.code)
                        }
                    }
                }
                Section("subscription_section") {
                    SubscriptionBadgeView()
                }
                Section("about_section") {
                    Link("privacy_policy", destination: URL(string: "https://notechain.app/privacy")!)
                    LabeledContent("version_label", value: Bundle.main.appVersionString)
                }
            }
            .navigationTitle("settings_title")
        }
    }
}
```

#### ViewModel 設計

```swift
// NoteChain/Features/Settings/SettingsViewModel.swift
@MainActor
@Observable
final class SettingsViewModel {
    // --- @AppStorage 永続化プロパティ ---
    @AppStorage("recordingLanguage") var recordingLanguage: String = "en-US"
    @AppStorage("uiLanguage") var uiLanguage: String = "system"
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("weeklyNoteCount") var weeklyNoteCount: Int = 0
    @AppStorage("weeklyNoteCountResetDate") var weeklyNoteCountResetDate: Double = Date().timeIntervalSince1970

    // --- 計算プロパティ ---
    var speechLocale: Locale { Locale(identifier: recordingLanguage) }
    var isAutoDetectLanguage: Bool { recordingLanguage == "auto" }

    // --- 静的定義 ---
    static let supportedRecordingLanguages: [(code: String, name: String, flag: String)] = [
        ("auto",  "Auto Detect",   "🌐"),
        ("en-US", "English (US)", "🇺🇸"),
        ("ja-JP", "日本語",        "🇯🇵"),
        ("es-ES", "Español",       "🇪🇸"),
    ]

    static let supportedUILanguages: [(code: String, name: String)] = [
        ("system", "System Default"),
        ("en",     "English"),
        ("ja",     "日本語"),
        ("es",     "Español"),
    ]

    // --- 公開メソッド ---
    func resetWeeklyCountIfNeeded() { ... }   // 月曜日にカウントリセット
    func incrementWeeklyNoteCount() { ... }
}
```

**公開プロパティ一覧:**

| プロパティ | 型 | 永続化 | 説明 |
|-----------|-----|--------|------|
| `recordingLanguage` | `String` | @AppStorage | ロケール識別子（"en-US" / "ja-JP" / "es-ES" / "auto"） |
| `uiLanguage` | `String` | @AppStorage | UI言語（"system" / "en" / "ja" / "es"） |
| `hasCompletedOnboarding` | `Bool` | @AppStorage | オンボーディング完了フラグ |
| `weeklyNoteCount` | `Int` | @AppStorage | 今週のノート作成数（無料枠チェック用） |
| `speechLocale` | `Locale` | 計算 | `recordingLanguage` から生成したロケール |

#### 依存するモジュール・サービス

| 依存先 | 用途 |
|--------|------|
| `Features/Subscription/SubscriptionManager` | サブスクリプション状態表示 |
| `Features/Subscription/SubscriptionBadgeView` | Pro バッジ表示 |

---

### 2.5 Subscription — サブスクリプション

**責務:**  
StoreKit 2 を使って月額・年額プランの商品取得・購入・復元・トランザクション監視を行う。`isSubscribed` フラグを全モジュールが参照できるよう `@Environment` 経由で提供する。無料枠（週3件）のチェックロジックを持つ。

#### View 一覧

| ファイル | 役割 |
|---------|------|
| `PaywallView.swift` | ペイウォール画面。機能リスト・月額/年額プランボタン（おすすめバッジ付き）・14日間トライアル説明・復元ボタン・プライバシーポリシーリンク |
| `SubscriptionBadgeView.swift` | `isSubscribed` 状態を反映した小型バッジ（"Pro" / "Free"）。Settings画面やプロフィールで使用 |

```swift
// PaywallView の骨格
struct PaywallView: View {
    @State private var viewModel = PaywallViewModel()
    @Environment(SubscriptionManager.self) private var manager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ヘッダー
                PaywallHeaderView()

                // 機能リスト
                FeatureListView()

                // プラン選択
                ForEach(manager.products) { product in
                    ProductOptionButton(
                        product: product,
                        isSelected: viewModel.selectedProduct?.id == product.id,
                        isRecommended: product.id.contains("annual")
                    ) { viewModel.selectedProduct = product }
                }

                // CTA ボタン
                StartTrialButton(isLoading: manager.isLoading) {
                    Task {
                        if let product = viewModel.selectedProduct {
                            try? await manager.purchase(product)
                            dismiss()
                        }
                    }
                }

                // 復元・法的リンク
                RestoreAndLegalView()
            }
            .padding()
        }
    }
}
```

#### SubscriptionManager 設計

```swift
// NoteChain/Features/Subscription/SubscriptionManager.swift
import StoreKit

@MainActor
@Observable
final class SubscriptionManager {
    // --- 公開プロパティ ---
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isSubscribed: Bool = false
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var subscriptionExpirationDate: Date? = nil
    var daysRemainingInTrial: Int? = nil

    // --- 内部 ---
    private var transactionListener: Task<Void, Never>?

    static let productIDs: [String] = [
        "com.yourcompany.notechain.pro_monthly",
        "com.yourcompany.notechain.pro_annual"
    ]

    // --- 公開メソッド ---
    func initialize() async { ... }             // 起動時に呼ぶ。商品取得+購入状態更新+トランザクション監視開始
    func fetchProducts() async { ... }
    func purchase(_ product: Product) async throws { ... }
    func restorePurchases() async { ... }
    func canCreateNote(currentWeekNoteCount: Int) -> Bool { ... }    // isSubscribed || count < 3

    // --- 内部メソッド ---
    private func updatePurchasedProducts() async { ... }
    private func observeTransactionUpdates() -> Task<Void, Never> { ... }
    private func scheduleTrialReminders() async { ... }   // Day2/7/13 のローカル通知
}
```

**公開プロパティ一覧:**

| プロパティ | 型 | 説明 |
|-----------|-----|------|
| `products` | `[Product]` | StoreKit から取得した商品リスト（月額・年額） |
| `purchasedProductIDs` | `Set<String>` | 購入済みプロダクトID |
| `isSubscribed` | `Bool` | 有効サブスクリプションの有無 |
| `isLoading` | `Bool` | 商品取得・購入中フラグ |
| `errorMessage` | `String?` | エラーメッセージ |
| `subscriptionExpirationDate` | `Date?` | サブスク有効期限 |
| `daysRemainingInTrial` | `Int?` | トライアル残日数（nil = トライアル中ではない） |

#### 依存するモジュール・サービス

| 依存先 | 用途 |
|--------|------|
| StoreKit 2 (system) | 商品取得・購入・復元 |
| UserNotifications (system) | トライアルリマインダー通知 |
| `Features/Settings/SettingsViewModel` | weeklyNoteCount 参照 |

---

### 2.6 Onboarding — オンボーディング

**責務:**  
初回起動時のみ表示される3ステップフロー（マイク権限リクエスト → 録音言語選択 → ペイウォール）を管理し、完了後に `hasCompletedOnboarding = true` を設定してメイン画面へ遷移する。

#### View 一覧

| ファイル | 役割 |
|---------|------|
| `OnboardingView.swift` | TabView + PageStyle で3ステップを管理するコンテナ。各ページはサブビューとして定義（`OnboardingPermissionPage`, `OnboardingLanguagePage`, `OnboardingPaywallPage`） |

```swift
// OnboardingView の骨格
struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(SubscriptionManager.self) private var subscriptionManager

    var body: some View {
        TabView(selection: $viewModel.currentStep) {
            OnboardingPermissionPage(onGranted: { viewModel.advance() })
                .tag(OnboardingStep.permission)

            OnboardingLanguagePage(
                selectedLanguage: $viewModel.selectedLanguage,
                onNext: { viewModel.advance() }
            )
            .tag(OnboardingStep.language)

            OnboardingPaywallPage(
                manager: subscriptionManager,
                onComplete: { viewModel.complete() }
            )
            .tag(OnboardingStep.paywall)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .animation(.easeInOut, value: viewModel.currentStep)
    }
}
```

**OnboardingViewModel 設計:**

```swift
@MainActor
@Observable
final class OnboardingViewModel {
    // --- 公開プロパティ ---
    var currentStep: OnboardingStep = .permission
    var selectedLanguage: String = "en-US"
    var isComplete: Bool = false

    enum OnboardingStep: Int, CaseIterable {
        case permission = 0
        case language   = 1
        case paywall    = 2
    }

    // --- 公開メソッド ---
    func advance() { ... }
    func complete() { ... }   // hasCompletedOnboarding = true → isComplete = true
    func requestMicrophonePermission() async -> Bool { ... }
}
```

#### 依存するモジュール・サービス

| 依存先 | 用途 |
|--------|------|
| `Features/Subscription/PaywallView` | 最終ステップのペイウォール埋め込み |
| `Features/Settings/SettingsViewModel` | `recordingLanguage` / `hasCompletedOnboarding` 書き込み |
| `Shared/Models/AppError` | 権限エラー処理 |

---

## 3. Shared レイヤー設計

### 3.1 SpeechRecognitionService

**設計方針:** iOS バージョンによる実装の違いをプロトコルで完全に隠蔽する。呼び出し側は `SpeechRecognitionServiceProtocol` にのみ依存し、`SpeechRecognitionServiceFactory.create()` でインスタンスを取得する。

```swift
// NoteChain/Shared/Services/SpeechRecognitionService.swift
import Speech
import Foundation

// MARK: - 転写結果モデル
struct TranscriptionResult: Sendable, Equatable {
    let text: String
    let isFinal: Bool       // false = volatile（薄紫） / true = final（黒）
    let confidence: Double? // SpeechAnalyzer は nil、SFSpeechRecognizer は 0.0-1.0
    let timestamp: Date     // デバッグ・パフォーマンス計測用
}

// MARK: - プロトコル
protocol SpeechRecognitionServiceProtocol: Sendable {
    /// 音声認識ストリームを開始。各確定/暫定テキストを AsyncThrowingStream で配信
    func startRecognition(locale: Locale) -> AsyncThrowingStream<TranscriptionResult, Error>

    /// 認識を停止し、残りの未確定テキストを flush してストリームを終了
    func stopRecognition() async

    /// このデバイス・OSで利用可能かどうか（権限は含まない）
    var isAvailable: Bool { get async }
}

// MARK: - SpeechAnalyzer 実装（iOS 26+）
@available(iOS 26, *)
final class SpeechAnalyzerService: SpeechRecognitionServiceProtocol {
    private var transcriber: SpeechTranscriber?
    private var analyzer: SpeechAnalyzer?

    func startRecognition(locale: Locale) -> AsyncThrowingStream<TranscriptionResult, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let transcriber = SpeechTranscriber(
                    locale: locale,
                    preset: .progressiveLiveTranscription
                )
                self.transcriber = transcriber
                let analyzer = SpeechAnalyzer(modules: [transcriber])
                self.analyzer = analyzer

                do {
                    for try await result in transcriber.results {
                        continuation.yield(TranscriptionResult(
                            text: String(result.text.characters),
                            isFinal: result.isFinal,
                            confidence: nil,
                            timestamp: Date()
                        ))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func stopRecognition() async {
        try? await analyzer?.finalizeAndFinishThroughEndOfInput()
    }

    var isAvailable: Bool {
        get async { true }
    }
}

// MARK: - SFSpeechRecognizer フォールバック（iOS 17–25）
final class LegacySpeechService: NSObject, SpeechRecognitionServiceProtocol, @unchecked Sendable {
    // ※ NSObject 継承 + Task の外部からのキャンセルのため @unchecked Sendable を限定的に使用
    // ただし、internal stateへのアクセスは必ず同一 Task / 同一スレッドで実施することを保証
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func startRecognition(locale: Locale) -> AsyncThrowingStream<TranscriptionResult, Error> {
        AsyncThrowingStream { continuation in
            Task { @MainActor in
                let speechRecognizer = SFSpeechRecognizer(locale: locale)
                guard let recognizer = speechRecognizer, recognizer.isAvailable else {
                    continuation.finish(throwing: AppError.speechRecognitionUnavailable)
                    return
                }

                let engine = AVAudioEngine()
                self.audioEngine = engine

                let request = SFSpeechAudioBufferRecognitionRequest()
                request.requiresOnDeviceRecognition = true
                request.shouldReportPartialResults = true
                self.recognitionRequest = request

                self.recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                    if let result {
                        continuation.yield(TranscriptionResult(
                            text: result.bestTranscription.formattedString,
                            isFinal: result.isFinal,
                            confidence: Double(result.bestTranscription.segments.last?.confidence ?? 0),
                            timestamp: Date()
                        ))
                    }
                    if let error {
                        continuation.finish(throwing: error)
                    } else if result?.isFinal == true {
                        continuation.finish()
                    }
                }

                let inputNode = engine.inputNode
                let format = inputNode.outputFormat(forBus: 0)
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                    request.append(buffer)
                }

                do {
                    try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
                    try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                    try engine.start()
                } catch {
                    continuation.finish(throwing: AppError.audioEngineFailedToStart(error))
                }
            }
        }
    }

    func stopRecognition() async {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    var isAvailable: Bool {
        get async {
            await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }
}

// MARK: - ファクトリ
enum SpeechRecognitionServiceFactory {
    static func create() -> any SpeechRecognitionServiceProtocol {
        if #available(iOS 26, *) {
            return SpeechAnalyzerService()
        } else {
            return LegacySpeechService()
        }
    }
}
```

---

### 3.2 KeywordExtractor

> 詳細は [2.2 Keywords](#22-keywords-キーワード抽出) を参照。

**v1.1 Core ML 実装のプレースホルダ:**

```swift
// v1.1 で実装予定 — プロトコル準拠のみ変更
// final class CoreMLKeywordExtractor: KeywordExtractorProtocol {
//     private let model: KeywordExtractionModel  // Create ML 生成
//     func extract(from text: String, maxKeywords: Int) -> [(keyword: String, confidence: Double)] { ... }
// }
```

---

### 3.3 Router

```swift
// NoteChain/Shared/Navigation/Router.swift
import SwiftUI

// MARK: - Route 定義
enum Route: Hashable {
    // NotesList タブ内
    case noteDetail(UUID)
    case keywordFilter(String)

    // Settings タブ内
    case languagePicker
    case subscriptionManagement

    // Sheet / FullScreenCover（Router 外で管理）
    // .paywall は AppState.isShowingPaywall で管理
    // .onboarding は AppState.hasCompletedOnboarding で管理
}

// MARK: - Router (@Observable)
@MainActor
@Observable
final class Router {
    var notesPath: NavigationPath = NavigationPath()
    var settingsPath: NavigationPath = NavigationPath()

    // --- NavigationStack 操作 ---
    func push(_ route: Route, in tab: AppTab = .notes) {
        switch tab {
        case .notes:    notesPath.append(route)
        case .settings: settingsPath.append(route)
        case .record:   break
        }
    }

    func pop(from tab: AppTab = .notes) {
        switch tab {
        case .notes:    if !notesPath.isEmpty { notesPath.removeLast() }
        case .settings: if !settingsPath.isEmpty { settingsPath.removeLast() }
        case .record:   break
        }
    }

    func popToRoot(in tab: AppTab = .notes) {
        switch tab {
        case .notes:    notesPath = NavigationPath()
        case .settings: settingsPath = NavigationPath()
        case .record:   break
        }
    }
}

// MARK: - タブ定義
enum AppTab: String, CaseIterable, Identifiable {
    case record   = "record"
    case notes    = "notes"
    case settings = "settings"

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .record:   "recording_tab"
        case .notes:    "notes_tab"
        case .settings: "settings_tab"
        }
    }

    var systemImage: String {
        switch self {
        case .record:   "mic.circle.fill"
        case .notes:    "note.text"
        case .settings: "gearshape"
        }
    }
}
```

---

### 3.4 Note @Model

```swift
// NoteChain/Shared/Models/Note.swift
import SwiftData
import Foundation

@Model
final class Note {
    // MARK: - 永続化プロパティ
    @Attribute(.unique) var id: UUID
    var audioFileURL: URL?                      // ローカルオーディオファイルパス（任意）
    var transcript: String                      // 最終確定テキスト（フルテキスト検索対象）
    var keywords: [String]                      // 抽出済みキーワードリスト（順序あり）
    var keywordConfidences: [String: Double]    // キーワード→信頼度スコア（0.0–1.0）
    var createdAt: Date                         // 作成日時（ソート・セクション分けに使用）
    var updatedAt: Date                         // 最終更新日時
    var duration: TimeInterval                  // 録音時間（秒）
    var languageCode: String                    // 録音言語ロケール識別子（例: "ja-JP"）
    var isFavorite: Bool                        // お気に入りフラグ

    // MARK: - 計算プロパティ（@Model 非永続）
    var wordCount: Int {
        transcript.split(separator: " ").count
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var displayTitle: String {
        // transcript 先頭50文字をタイトルとして使用
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "untitled_note" }
        return String(trimmed.prefix(50))
    }

    var sectionDate: Date {
        // 日付セクション分け用（時刻を切り捨て）
        Calendar.current.startOfDay(for: createdAt)
    }

    var topKeywords: [String] {
        // 信頼度順の上位5キーワード
        keywords
            .sorted { (keywordConfidences[$0] ?? 0) > (keywordConfidences[$1] ?? 0) }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - イニシャライザ
    init(
        transcript: String = "",
        keywords: [String] = [],
        keywordConfidences: [String: Double] = [:],
        duration: TimeInterval = 0,
        languageCode: String = "en-US",
        audioFileURL: URL? = nil
    ) {
        self.id = UUID()
        self.transcript = transcript
        self.keywords = keywords
        self.keywordConfidences = keywordConfidences
        self.createdAt = Date()
        self.updatedAt = Date()
        self.duration = duration
        self.languageCode = languageCode
        self.audioFileURL = audioFileURL
        self.isFavorite = false
    }
}

// MARK: - SwiftData Schema Migration ガード
// v1.0: 初期スキーマ（マイグレーション不要）
// v1.1: CloudKit同期追加時に SchemaMigrationPlan を実装すること
```

**プロパティ一覧:**

| プロパティ | 型 | 永続化 | 説明 |
|-----------|-----|--------|------|
| `id` | `UUID` | ✅ @Attribute(.unique) | 一意識別子 |
| `audioFileURL` | `URL?` | ✅ | ローカル音声ファイルパス |
| `transcript` | `String` | ✅ | 確定済みテキスト全文 |
| `keywords` | `[String]` | ✅ | キーワードリスト |
| `keywordConfidences` | `[String: Double]` | ✅ | 信頼度スコアマップ |
| `createdAt` | `Date` | ✅ | 作成日時 |
| `updatedAt` | `Date` | ✅ | 更新日時 |
| `duration` | `TimeInterval` | ✅ | 録音秒数 |
| `languageCode` | `String` | ✅ | 録音言語 |
| `isFavorite` | `Bool` | ✅ | お気に入り |
| `wordCount` | `Int` | ❌ 計算 | 単語数 |
| `formattedDuration` | `String` | ❌ 計算 | "MM:SS" 形式 |
| `displayTitle` | `String` | ❌ 計算 | transcript 先頭50文字 |
| `sectionDate` | `Date` | ❌ 計算 | セクション分け用日付 |
| `topKeywords` | `[String]` | ❌ 計算 | 信頼度上位5キーワード |

---

### 3.5 AppError

```swift
// NoteChain/Shared/Models/AppError.swift
import Foundation

enum AppError: LocalizedError, Equatable {
    // MARK: - 音声認識エラー
    case microphonePermissionDenied
    case speechRecognitionPermissionDenied
    case speechRecognitionUnavailable
    case audioEngineFailedToStart(Error)
    case audioSessionInterrupted
    case recognitionTaskFailed(Error)

    // MARK: - データエラー
    case noteNotFound(UUID)
    case swiftDataSaveFailed(Error)
    case swiftDataFetchFailed(Error)
    case noteDeleteFailed(Error)

    // MARK: - キーワード抽出エラー
    case keywordExtractionFailed(String)
    case emptyTranscriptForExtraction

    // MARK: - サブスクリプションエラー
    case productFetchFailed(Error)
    case purchaseFailed(Error)
    case restorePurchaseFailed(Error)
    case weeklyLimitReached                // 無料枠上限

    // MARK: - LocalizedError 準拠
    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return String(localized: "error_microphone_denied")
        case .speechRecognitionPermissionDenied:
            return String(localized: "error_speech_permission_denied")
        case .speechRecognitionUnavailable:
            return String(localized: "error_speech_unavailable")
        case .audioEngineFailedToStart(let error):
            return String(localized: "error_audio_engine") + ": \(error.localizedDescription)"
        case .audioSessionInterrupted:
            return String(localized: "error_audio_interrupted")
        case .recognitionTaskFailed(let error):
            return String(localized: "error_recognition_failed") + ": \(error.localizedDescription)"
        case .noteNotFound(let id):
            return String(localized: "error_note_not_found") + ": \(id)"
        case .swiftDataSaveFailed(let error):
            return String(localized: "error_save_failed") + ": \(error.localizedDescription)"
        case .swiftDataFetchFailed(let error):
            return String(localized: "error_fetch_failed") + ": \(error.localizedDescription)"
        case .noteDeleteFailed(let error):
            return String(localized: "error_delete_failed") + ": \(error.localizedDescription)"
        case .keywordExtractionFailed(let reason):
            return String(localized: "error_keyword_extraction") + ": \(reason)"
        case .emptyTranscriptForExtraction:
            return String(localized: "error_empty_transcript")
        case .productFetchFailed(let error):
            return String(localized: "error_product_fetch") + ": \(error.localizedDescription)"
        case .purchaseFailed(let error):
            return String(localized: "error_purchase") + ": \(error.localizedDescription)"
        case .restorePurchaseFailed(let error):
            return String(localized: "error_restore") + ": \(error.localizedDescription)"
        case .weeklyLimitReached:
            return String(localized: "error_weekly_limit")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .microphonePermissionDenied, .speechRecognitionPermissionDenied:
            return String(localized: "recovery_open_settings")
        case .weeklyLimitReached:
            return String(localized: "recovery_upgrade_pro")
        default:
            return String(localized: "recovery_try_again")
        }
    }

    // Equatable 準拠（Associated value に Error を持つケースは簡易比較）
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.microphonePermissionDenied, .microphonePermissionDenied),
             (.speechRecognitionPermissionDenied, .speechRecognitionPermissionDenied),
             (.speechRecognitionUnavailable, .speechRecognitionUnavailable),
             (.audioSessionInterrupted, .audioSessionInterrupted),
             (.emptyTranscriptForExtraction, .emptyTranscriptForExtraction),
             (.weeklyLimitReached, .weeklyLimitReached):
            return true
        case (.noteNotFound(let a), .noteNotFound(let b)):
            return a == b
        default:
            return false
        }
    }
}
```

---

## 4. 画面遷移図

```
┌─────────────────────────────────────────────────────────────────┐
│                    NoteChain 画面遷移図                          │
│  ──── push/pop (NavigationStack)                                │
│  ═══ fullScreenCover                                            │
│  ···· sheet                                                     │
└─────────────────────────────────────────────────────────────────┘

[起動]
  │
  ▼
AppState.hasCompletedOnboarding?
  │
  ├─ false ════════════════════════════════════════════╗
  │                                                    ║
  │   ╔══════════════════════════════════════════════╗ ║
  │   ║  OnboardingView (.fullScreenCover)           ║◄╝
  │   ║  ┌─────────────────────────────────┐         ║
  │   ║  │ Page 1: OnboardingPermissionPage│         ║
  │   ║  │  マイク/音声認識 権限リクエスト   │         ║
  │   ║  │  [許可する] → advance()          │         ║
  │   ║  └─────────────────────────────────┘         ║
  │   ║  ┌─────────────────────────────────┐         ║
  │   ║  │ Page 2: OnboardingLanguagePage  │         ║
  │   ║  │  録音言語選択                    │         ║
  │   ║  │  [次へ] → advance()             │         ║
  │   ║  └─────────────────────────────────┘         ║
  │   ║  ┌─────────────────────────────────┐         ║
  │   ║  │ Page 3: OnboardingPaywallPage   │         ║
  │   ║  │  ＝ PaywallView の埋め込み       │         ║
  │   ║  │  [14日間トライアル開始]          │         ║
  │   ║  │  → complete() → dismiss         │         ║
  │   ║  └─────────────────────────────────┘         ║
  │   ╚══════════════════════════════════════════════╝
  │
  └─ true
       │
       ▼
  ┌──────────────────────────────────────────────────────┐
  │  ContentView (TabView)                               │
  │  ┌────────────┬────────────────┬──────────────┐      │
  │  │  🎙 録音   │  📝 ノート      │  ⚙ 設定     │      │
  │  └─────┬──────┴───────┬────────┴──────┬───────┘      │
  │        │              │               │               │
  │        ▼              ▼               ▼               │
  │  RecordingView  NotesListView    SettingsView         │
  └──────────────────────────────────────────────────────┘

═══════════════════════════════════════════════
  🎙 録音タブ: RecordingView
═══════════════════════════════════════════════

RecordingView
  │
  ├── [権限拒否状態] PermissionDeniedView（インライン表示）
  │     └── [設定を開く] → UIApplication.openSettings()
  │
  ├── [録音中] RecordingTimerView（インライン表示）
  │
  ├── [週3件制限・無料ユーザー]
  │     └── PaywallView ···················· (.sheet)
  │           └── [トライアル開始 / 購入]
  │                 └── dismiss → 録音再開
  │
  └── [録音完了・Note保存後]
        └── NoteDetailView ──────────────── (push via Router)
              └── [< 戻る] → pop

═══════════════════════════════════════════════
  📝 ノートタブ: NavigationStack
═══════════════════════════════════════════════

NotesListView
  │
  ├── [検索バー] searchable → filteredNotes 更新
  │
  ├── [ソートメニュー] ToolbarMenu → sortOrder 更新
  │
  ├── NoteRowView（各行）
  │     └── [タップ] ──────────────────────── push: noteDetail(UUID)
  │           │
  │           ▼
  │     NoteDetailView
  │           │
  │           ├── [編集ボタン] isEditing = true（インライン編集）
  │           │     └── [保存] saveEdit() → キーワード再抽出
  │           │
  │           ├── KeywordBadgeView（各バッジ）
  │           │     └── [タップ] → push: keywordFilter(keyword)
  │           │           │
  │           │           ▼
  │           │     NotesListView（フィルタ適用済み）
  │           │           └── [< 戻る] pop
  │           │
  │           └── [削除ボタン]
  │                 └── ConfirmationDialog ·· (.confirmationDialog)
  │                       └── [削除確認] → pop → NotesListView更新
  │
  └── [スワイプ削除] → deleteNotes() → リスト更新

═══════════════════════════════════════════════
  ⚙ 設定タブ: NavigationStack
═══════════════════════════════════════════════

SettingsView
  │
  ├── [録音言語セクション]
  │     └── LanguagePickerView ────────────── push: languagePicker
  │           └── [言語選択] → recordingLanguage 更新 → pop
  │
  ├── [サブスクリプション]
  │     └── SubscriptionBadgeView
  │           └── [タップ（Free時）] ·········· (.sheet)
  │                 PaywallView
  │                   └── [購入 / トライアル] → dismiss
  │
  └── [プライバシーポリシー] → SafariView ···· (.sheet)

═══════════════════════════════════════════════
  グローバル Sheet / FullScreenCover
═══════════════════════════════════════════════

AppState.isShowingPaywall == true
  └── PaywallView ════════════════════════════ (.sheet, グローバル)
        └── dismiss → isShowingPaywall = false

AppState.isShowingOnboarding == true
  └── OnboardingView ═════════════════════════ (.fullScreenCover, グローバル)
        └── complete() → isShowingOnboarding = false
```

---

## 5. .claude/rules/ ルールファイル設計

### 5.1 `general.md`

**ファイルパス:** `.claude/rules/general.md`  
**paths 指定:** なし（常時ロード）  
**目的:** プロジェクト全体に適用する絶対ルール。AIが最初に読むべき基礎設計方針。

**主要ルール:**

1. **Vertical Slice 遵守**: 機能追加は必ず `Features/<FeatureName>/` 内に閉じること。Shared レイヤーへの昇格は2つ以上のモジュールで使う場合のみ
2. **ARCHITECTURE.md 参照必須**: 実装前に `docs/ARCHITECTURE.md` の該当モジュール設計を確認し、プロパティ・メソッド名を設計書と一致させること
3. **ファイル新規作成前の確認**: 同じ責務を持つファイルが既に存在しないか検索すること（重複防止）
4. **README.md 更新**: 各 Feature ディレクトリの `README.md` に変更内容を反映すること
5. **ハードコード禁止**: UI文字列は必ず `Localizable.xcstrings` のキーを使用すること
6. **SwiftData は ModelContext 経由**: `@Query` マクロはテスト困難なため使わず、ModelContext を ViewModel に DI する
7. **依存方向の厳守**: `Features → Shared` は可。`Shared → Features` は不可。`Features ↔ Features` は Router/Environment 経由のみ
8. **Magic Number 禁止**: 定数は `enum Constants` または `extension` で名前付きで定義
9. **TODO コメント禁止**: 未実装箇所は GitHub Issue を作成し、コメントに Issue 番号を記載
10. **最低 iOS 17.0**: `@available(iOS 17, *)` より古い API は使用しない

---

### 5.2 `security.md`

**ファイルパス:** `.claude/rules/security.md`  
**paths 指定:** なし（常時ロード）  
**目的:** プライバシーファーストの設計を担保する。セキュリティ違反はレビューで即時リジェクト。

**主要ルール:**

1. **ネットワーク通信禁止（MVP）**: URLSession, Alamofire, その他ネットワークライブラリの使用を禁止。唯一の例外は StoreKit 2 と TelemetryDeck（オプション）
2. **requiresOnDeviceRecognition = true 必須**: `SFSpeechAudioBufferRecognitionRequest` では必ず `requiresOnDeviceRecognition = true` を設定すること
3. **マイク使用は録音中のみ**: `AVAudioSession` は録音開始時のみ `.record` カテゴリでアクティベート。停止後は即座に `setActive(false)` を呼ぶ
4. **ファイル保護**: SwiftData ストアと音声ファイルには `NSFileProtectionComplete` を適用すること
5. **ログに個人情報を含めない**: `print()` / `Logger` でのトランスクリプト内容の出力を禁止。デバッグビルドのみ許可し `#if DEBUG` で囲む
6. **サードパーティ SDK 追加禁止**: CocoaPods / SPM での外部依存追加は必ずレビュー承認後。MVP では一切追加しない
7. **Keychain 使用制限**: API キー等の機密情報は Keychain に保存。UserDefaults / @AppStorage への保存は禁止
8. **Info.plist 権限説明の明確化**: `NSMicrophoneUsageDescription` と `NSSpeechRecognitionUsageDescription` は具体的な利用目的を日本語・英語・スペイン語で記載

---

### 5.3 `swift-style.md`

**ファイルパス:** `.claude/rules/swift-style.md`  
**paths 指定:** `**/*.swift`  
**目的:** Swift 6 Strict Concurrency に準拠したコードスタイルを強制する。

**主要ルール:**

1. **@MainActor 必須**: すべての ViewModel クラスは `@MainActor` で隔離すること。クラス宣言の直前に記述
2. **async/await のみ**: `DispatchQueue.global()`, `OperationQueue`, Combine の `Publisher` は使用禁止。非同期処理は `async/await` + `Task` のみ
3. **Task のキャンセル管理**: `Task {}` を生成した場合は必ず `task?.cancel()` を `deinit` や `onDisappear` で呼ぶ。`Task.detached` は最小限に限定
4. **Sendable 準拠**: `@Model` クラスを除き、非同期コンテキストを跨ぐすべての型は `Sendable` または `@Sendable` を明示すること
5. **@unchecked Sendable の禁止**: `@unchecked Sendable` は設計書で承認された箇所（`LegacySpeechService`）以外への使用を禁止
6. **ModelActor の使用**: バックグラウンドスレッドでの SwiftData 書き込みは `@ModelActor` で隔離した Actor を使うこと
7. **`nonisolated(unsafe)` 禁止**: Swift 6 において `nonisolated(unsafe)` の使用を一切禁止
8. **型推論の活用**: 型が明白な場合は型注釈を省略。ただし、関数の戻り値と公開プロパティには型を明示すること
9. **エラーハンドリング**: `try?` の使用は原則禁止。`do/catch` で `AppError` にラップして ViewModel の `errorMessage` に格納
10. **import の整理**: Apple フレームワークを先頭に、アルファベット順で列挙。不要な import は削除

---

### 5.4 `swiftui.md`

**ファイルパス:** `.claude/rules/swiftui.md`  
**paths 指定:** `**/*View.swift`  
**目的:** SwiftUI 固有のアンチパターンを防止し、パフォーマンスと可読性を確保する。

**主要ルール:**

1. **@State でのみ ViewModel を保持**: View 内 ViewModel は `@State private var viewModel = XxxViewModel()` のみ。`@StateObject` / `@ObservedObject` / `@Published` は使用禁止
2. **EnvironmentObject 禁止**: グローバル共有は `@Environment(\.xxx)` または `@Environment(XxxType.self)` を使用
3. **View の body は100行以内**: 100行を超える場合はサブビューを抽出すること
4. **`.task {}` でのみ非同期処理を開始**: View 表示時の非同期処理は `.task { await viewModel.load() }` パターンを使用。`.onAppear` での `Task {}` 生成は禁止
5. **プレビュー必須**: すべての View に `#Preview {}` を実装すること。ViewModel の依存は必ずモックを渡す
6. **アニメーション**: 状態変化に伴うアニメーションは `.animation(.easeInOut, value: xxx)` で明示的に指定
7. **アクセシビリティ**: インタラクティブ要素には `.accessibilityLabel()` を付与。画像には `.accessibilityHidden(true)` または代替テキストを設定
8. **ローカライズ必須**: テキストはすべて `Text("localization_key")` または `LocalizedStringKey` 経由。ハードコード文字列は禁止
9. **条件分岐 View**: `if viewModel.isLoading { LoadingOverlay() }` のような条件 View は `@ViewBuilder` な関数に抽出する
10. **GeometryReader の最小化**: レイアウトに `GeometryReader` を多用しない。SwiftUI のネイティブレイアウト API（`.frame()`, `.padding()` など）を優先

---

### 5.5 `swiftdata.md`

**ファイルパス:** `.claude/rules/swiftdata.md`  
**paths 指定:** `**/Models/**/*.swift`  
**目的:** SwiftData の正しい使用パターンを強制し、データ整合性を保護する。

**主要ルール:**

1. **@Model は final class のみ**: `@Model` は `final class` に付与すること。`struct` への適用は禁止
2. **@Query 禁止**: テスト困難なため `@Query` マクロは使用しない。代わりに ViewModel で `ModelContext.fetch(FetchDescriptor<T>())` を使用
3. **ModelContext の DI**: ViewModel のイニシャライザで `ModelContext` を受け取る。`@Environment(\.modelContext)` は View で取得し ViewModel に渡す
4. **バックグラウンド書き込みは ModelActor**: 大量データの書き込みは `@ModelActor` 隔離 Actor 内で実行し、メインスレッドをブロックしない
5. **Relationship の明示**: 将来的に Relationship を追加する際は `@Relationship(deleteRule: .cascade)` を明示すること
6. **スキーマバージョン管理**: `ModelConfiguration` 使用時は `isStoredInMemoryOnly` をテスト環境で `true` にすること
7. **Unique 制約の活用**: 同一 UUID の重複挿入を防ぐため `@Attribute(.unique)` を `id` に付与（設計書記載済み）
8. **エラーはすべて catch**: `modelContext.save()` は必ず `try` + `catch` で囲み、`AppError.swiftDataSaveFailed` にラップする

---

### 5.6 `testing.md`

**ファイルパス:** `.claude/rules/testing.md`  
**paths 指定:** `**/*Tests.swift`  
**目的:** Swift Testing フレームワーク（`@Test`, `#expect`）の正しい使用パターンと、テスト品質基準を定義する。

**主要ルール:**

1. **Swift Testing のみ**: `XCTestCase` は使用禁止。すべてのテストは `import Testing` + `@Suite` / `@Test` で記述
2. **テスト命名規則**: `@Test("Given: ..., When: ..., Then: ...")` 形式でテスト意図を明示
3. **MockSpeechService 必須**: `SpeechRecognitionServiceProtocol` を実装した `MockSpeechService` をテストで使用。実際の音声 API は呼ばない
4. **InMemory SwiftData**: テスト用 `ModelContainer` は `ModelConfiguration(isStoredInMemoryOnly: true)` で生成
5. **非同期テストは async**: `@Test func testAsync() async { ... }` + `await` で非同期テストを記述。`expectation` / `XCTestExpectation` は使わない
6. **境界値テスト必須**: 空文字列、1000件のノート、極短・極長テキストなど境界値を必ず含める
7. **テストの独立性**: 各テストは他のテストに依存しないこと。`@Suite` の `init()` でセットアップ、`deinit` でクリーンアップ
8. **UIテストは最小限**: UIテストは Recording フロー・Paywall の主要フローのみ。ViewModel ロジックはユニットテストで担保
9. **テストカバレッジ目標**: ViewModel・Service クラスは 80% 以上のカバレッジを目指す
10. **パフォーマンステスト**: キーワード抽出（100語・1秒以内）と検索（1000件・500ms以内）のパフォーマンスアサーションを含める

---

### 5.7 `subscription.md`

**ファイルパス:** `.claude/rules/subscription.md`  
**paths 指定:** `**/Subscription/**/*.swift`  
**目的:** StoreKit 2 の正しい実装パターンを強制し、App Store ガイドライン違反を防止する。

**主要ルール:**

1. **Transaction.updates の監視必須**: アプリ起動時に必ず `Transaction.updates` の非同期ループを開始し、外部からのトランザクション更新（払い戻し等）を処理すること
2. **payloadValue で検証**: `VerificationResult` は必ず `.payloadValue` で署名検証を行うこと。`.unsafePayloadValue` は使用禁止
3. **transaction.finish() 必須**: 購入完了後は必ず `await transaction.finish()` を呼ぶこと。未完了トランザクションはユーザーに重複課金リスクを生む
4. **price は Product から取得**: 表示価格は `product.displayPrice` を使用。ハードコード価格の表示は禁止（App Store ガイドライン違反）
5. **AppStore.sync() のみで復元**: 購入復元は `AppStore.sync()` を使用。`SKPaymentQueue.restoreCompletedTransactions()` は使用禁止（StoreKit 2 非推奨）
6. **isLoading フラグの管理**: 購入処理中は `isLoading = true` にしてボタンを無効化し、多重購入を防ぐ
7. **TestFlight での Sandbox テスト**: Sandbox 環境ではトランザクションが異なる。テスト手順に Sandbox アカウントの設定を含めること
8. **プロダクト ID は定数で管理**: プロダクト ID は `SubscriptionManager.productIDs` の静的配列で一元管理。コード内に文字列リテラルでの記述禁止
9. **ペイウォールのキャンセルを妨げない**: ペイウォール画面には必ず閉じるボタン（dismiss）を設置。App Store ガイドライン 3.1.1 への準拠
10. **無料枠チェックはサーバーレス**: `canCreateNote(currentWeekNoteCount:)` は `@AppStorage` のローカル値のみで判定。外部検証は不要（オフライン対応）

---

## 6. 開発フェーズ（6週間）

### Week 1: AI駆動開発基盤 & スキャフォールディング

**実装するモジュール:** App 基盤, Shared レイヤー全体, 全 Feature スケルトン

#### 作成ファイル一覧

| ファイルパス | 推定行数 | 説明 |
|------------|---------|------|
| `CLAUDE.md` | 150 | AI 駆動開発メイン指示書 |
| `AGENTS.md` | 20 | CLAUDE.md インポート |
| `.claude/rules/general.md` | 80 | 全体ルール |
| `.claude/rules/security.md` | 70 | セキュリティルール |
| `.claude/rules/swift-style.md` | 90 | Swift 6 Concurrency ルール |
| `.claude/rules/swiftui.md` | 80 | SwiftUI パターン |
| `.claude/rules/swiftdata.md` | 70 | SwiftData 規約 |
| `.claude/rules/testing.md` | 80 | Swift Testing 規約 |
| `.claude/rules/subscription.md` | 90 | StoreKit 2 規約 |
| `.claude/skills/implement-feature/SKILL.md` | 60 | フィーチャー実装スキル |
| `.claude/skills/code-review/SKILL.md` | 50 | コードレビュースキル |
| `.claude/skills/test-generator/SKILL.md` | 50 | テスト生成スキル |
| `.claude/commands/build.md` | 20 | `/build` コマンド |
| `.claude/commands/test.md` | 20 | `/test` コマンド |
| `.claude/commands/generate-spec.md` | 30 | `/generate-spec` コマンド |
| `.claude/commands/generate-tasks.md` | 30 | `/generate-tasks` コマンド |
| `.claude/commands/implement-feature.md` | 40 | `/implement-feature` コマンド |
| `.claude/settings.json` | 20 | Claude Code 設定 |
| `.mcp.json` | 30 | XcodeBuildMCP 設定 |
| `docs/ARCHITECTURE.md` | 900 | 本設計書 |
| `docs/specs/template.md` | 40 | 仕様書テンプレート |
| `NoteChain/App/NoteChainApp.swift` | 50 | @main エントリポイント |
| `NoteChain/App/ContentView.swift` | 60 | TabView + Router |
| `NoteChain/App/AppState.swift` | 60 | アプリ全体状態 |
| `NoteChain/Shared/Models/Note.swift` | 90 | @Model 定義 |
| `NoteChain/Shared/Models/AppError.swift` | 100 | エラー enum |
| `NoteChain/Shared/Navigation/Router.swift` | 80 | ルーター |
| `NoteChain/Shared/Services/SpeechRecognitionService.swift` | 30 | プロトコルのみ（スケルトン） |
| `NoteChain/Shared/Extensions/Date+Formatting.swift` | 40 | 日付拡張 |
| `NoteChain/Shared/Extensions/String+Localized.swift` | 20 | ローカライズ拡張 |
| `NoteChain/Shared/Components/LoadingOverlay.swift` | 30 | ローディング |
| `NoteChain/Shared/Components/EmptyStateView.swift` | 40 | 空状態 |
| `NoteChain/Shared/Components/PermissionDeniedView.swift` | 50 | 権限拒否 |
| `NoteChain/Features/Recording/RecordingView.swift` | 80 | スケルトン（ボタン + プレースホルダ） |
| `NoteChain/Features/Recording/RecordingViewModel.swift` | 60 | スケルトン |
| `NoteChain/Features/Recording/RecordingManager.swift` | 50 | スケルトン |
| `NoteChain/Features/Recording/README.md` | 30 | モジュール説明 |
| `NoteChain/Features/Keywords/KeywordExtractor.swift` | 30 | プロトコルのみ |
| `NoteChain/Features/Keywords/KeywordBadgeView.swift` | 40 | スケルトン |
| `NoteChain/Features/Keywords/README.md` | 25 | モジュール説明 |
| `NoteChain/Features/NotesList/NotesListView.swift` | 60 | スケルトン |
| `NoteChain/Features/NotesList/NotesListViewModel.swift` | 50 | スケルトン |
| `NoteChain/Features/NotesList/NoteRowView.swift` | 40 | スケルトン |
| `NoteChain/Features/NotesList/NoteDetailView.swift` | 50 | スケルトン |
| `NoteChain/Features/NotesList/NoteDetailViewModel.swift` | 40 | スケルトン |
| `NoteChain/Features/NotesList/README.md` | 25 | モジュール説明 |
| `NoteChain/Features/Settings/SettingsView.swift` | 50 | スケルトン |
| `NoteChain/Features/Settings/SettingsViewModel.swift` | 60 | @AppStorage プロパティのみ |
| `NoteChain/Features/Settings/LanguagePickerView.swift` | 40 | スケルトン |
| `NoteChain/Features/Settings/README.md` | 25 | モジュール説明 |
| `NoteChain/Features/Subscription/PaywallView.swift` | 60 | スケルトン |
| `NoteChain/Features/Subscription/SubscriptionManager.swift` | 50 | スケルトン |
| `NoteChain/Features/Subscription/SubscriptionBadgeView.swift` | 30 | スケルトン |
| `NoteChain/Features/Subscription/README.md` | 25 | モジュール説明 |
| `NoteChain/Features/Onboarding/OnboardingView.swift` | 50 | スケルトン |
| `NoteChain/Features/Onboarding/OnboardingViewModel.swift` | 40 | スケルトン |
| `NoteChain/Features/Onboarding/README.md` | 25 | モジュール説明 |
| `NoteChain/Resources/Localizable.xcstrings` | 150 | 初期キー（en/ja/es） |
| `NoteChainTests/Shared/Models/NoteTests.swift` | 80 | Note @Model テスト |

**推定総行数:** 約 3,300 行

#### 受け入れ基準（Week 1）

```
Given: XcodeBuildMCP がセットアップ済み
When:  /build コマンドを実行
Then:  ビルドエラー 0、警告 0 でビルドが成功する

Given: アプリを iOS 17.0 シミュレータで起動
When:  初回起動
Then:  TabView が表示され、3タブ（録音・ノート・設定）が切り替え可能である

Given: SwiftData スキーマが定義済み
When:  NoteTests を実行
Then:  Note の init・wordCount・formattedDuration・displayTitle・sectionDate のテストが全パスする

Given: Router が初期化済み
When:  `router.push(.noteDetail(UUID()))` を呼ぶ
Then:  notesPath に Route が追加され、`router.pop()` で削除される

Given: AppState を初期化
When:  `hasCompletedOnboarding == false` の状態
Then:  OnboardingView（fullScreenCover）が表示されることをプレビューで確認できる
```

**前週への依存関係:** なし（Week 1 は基盤）

---

### Week 2: 音声認識統合

**実装するモジュール:** `Recording` 完全実装, `Shared/Services/SpeechRecognitionService` 完全実装

#### 作成・更新ファイル一覧

| ファイルパス | 推定行数 | 説明 |
|------------|---------|------|
| `NoteChain/Shared/Services/SpeechRecognitionService.swift` | 200 | プロトコル + SpeechAnalyzerService + LegacySpeechService + Factory |
| `NoteChain/Features/Recording/RecordingViewModel.swift` | 180 | 完全実装（状態管理・権限・保存） |
| `NoteChain/Features/Recording/RecordingManager.swift` | 120 | AVAudioSession ライフサイクル・割り込み処理 |
| `NoteChain/Features/Recording/RecordingView.swift` | 200 | 完全UI（ボタン・リアルタイムテキスト・タイマー・権限バナー） |
| `NoteChainTests/Features/Recording/RecordingViewModelTests.swift` | 180 | ViewModel テスト（モック使用） |

**推定総行数:** 約 880 行

#### 主要実装詳細

```swift
// RecordingViewModel の toggleRecording 実装例
func toggleRecording() async {
    if isRecording {
        await stopAndSave()
    } else {
        guard await requestPermissionsIfNeeded() else {
            permissionDenied = true
            return
        }
        // 無料枠チェック
        guard subscriptionManager.canCreateNote(currentWeekNoteCount: settingsViewModel.weeklyNoteCount) else {
            showPaywall = true
            return
        }
        await startRecording(locale: settingsViewModel.speechLocale)
    }
}

private func startRecording(locale: Locale) async {
    isRecording = true
    finalTranscript = ""
    volatileTranscript = ""
    recordingStartTime = Date()
    startDurationTimer()

    recognitionTask = Task {
        do {
            for try await result in speechService.startRecognition(locale: locale) {
                if result.isFinal {
                    finalTranscript += result.text + " "
                    volatileTranscript = ""
                } else {
                    volatileTranscript = result.text
                }
            }
        } catch {
            errorMessage = AppError.recognitionTaskFailed(error).errorDescription
        }
    }
}
```

#### 受け入れ基準（Week 2）

```
Given: iOS 26+ シミュレータ + マイク権限付与済み
When:  録音ボタンをタップして英語で話す
Then:  500ms以内に volatile テキストが薄紫色で表示され始める

Given: 録音中（10秒経過）
When:  停止ボタンをタップ
Then:  isSaving = true の後、SwiftData に Note が保存され、didSaveNote = true になる

Given: マイク権限が未付与
When:  録音ボタンをタップ
Then:  iOS 標準の権限リクエストダイアログが表示される

Given: マイク権限を拒否済み
When:  RecordingView が表示される
Then:  PermissionDeniedView が表示され、[設定を開く] でiOS設定に遷移する

Given: iOS 17.0 シミュレータ
When:  SpeechRecognitionServiceFactory.create() を呼ぶ
Then:  LegacySpeechService インスタンスが返される（SpeechAnalyzerService ではない）
```

**前週への依存関係:**
- Week 1: `Note.swift` (@Model), `AppError.swift`, `Router.swift`, スケルトン View/ViewModel

---

### Week 3: キーワード抽出 & ノート一覧

**実装するモジュール:** `Keywords` 完全実装, `NotesList` 完全実装

#### 作成・更新ファイル一覧

| ファイルパス | 推定行数 | 説明 |
|------------|---------|------|
| `NoteChain/Features/Keywords/KeywordExtractor.swift` | 150 | NLTaggerKeywordExtractor 完全実装 + Factory |
| `NoteChain/Features/Keywords/KeywordBadgeView.swift` | 60 | バッジ UI（削除ボタン付き） |
| `NoteChain/Features/Recording/RecordingViewModel.swift` | +30 | stopAndSave() に KeywordExtractor 連携を追加 |
| `NoteChain/Features/NotesList/NotesListView.swift` | 180 | 完全実装（検索・ソート・セクション・スワイプ削除） |
| `NoteChain/Features/NotesList/NotesListViewModel.swift` | 150 | 完全実装（filteredNotes・groupedNotes・delete） |
| `NoteChain/Features/NotesList/NoteRowView.swift` | 80 | 行 UI（タイトル・バッジ・時刻・時間） |
| `NoteChain/Features/NotesList/NoteDetailView.swift` | 160 | 詳細 UI（インライン編集・キーワード編集・削除） |
| `NoteChain/Features/NotesList/NoteDetailViewModel.swift` | 120 | 詳細 ViewModel（編集・再抽出・削除） |
| `NoteChainTests/Features/Keywords/KeywordExtractorTests.swift` | 120 | 英語・日本語・スペイン語テスト |
| `NoteChainTests/Features/NotesList/NotesListViewModelTests.swift` | 150 | 検索・ソート・削除テスト |

**推定総行数:** 約 1,200 行

#### 主要実装詳細

```swift
// NotesListViewModel.groupedNotes 実装例
var groupedNotes: [Date: [Note]] {
    Dictionary(grouping: filteredNotes) { $0.sectionDate }
}

var filteredNotes: [Note] {
    let descriptor = FetchDescriptor<Note>(
        predicate: languageFilter.map { lang in #Predicate { $0.languageCode == lang } },
        sortBy: [sortOrder.sortDescriptor]
    )
    let allNotes = (try? modelContext.fetch(descriptor)) ?? []

    guard !searchText.isEmpty else { return allNotes }

    return allNotes.filter { note in
        note.transcript.localizedCaseInsensitiveContains(searchText) ||
        note.keywords.contains { $0.localizedCaseInsensitiveContains(searchText) }
    }
}
```

#### 受け入れ基準（Week 3）

```
Given: "Had a meeting with the marketing team about Q2 planning." というテキスト
When:  NLTaggerKeywordExtractor.extract(from:maxKeywords:5) を呼ぶ
Then:  1秒以内に ["marketing", "meeting", "campaign", "planning", "media"] 相当の
       名詞キーワードが信頼度スコート付きで返される

Given: 日本語テキスト「マーケティングチームとの会議について議論した」
When:  キーワード抽出を実行
Then:  "マーケティング"・"会議"・"チーム" 等の日本語名詞が抽出される

Given: 10件のノートが SwiftData に存在する
When:  NotesListView を表示
Then:  新しい順（createdAt 降順）で全ノートが日付セクション区切りで表示される

Given: ノート一覧が表示されている
When:  "marketing" と検索バーに入力
Then:  transcript か keywords に "marketing" を含むノートのみリストに残る

Given: ノート一覧で1件のノートをスワイプ
When:  削除ボタンをタップして確認
Then:  そのノートが SwiftData から削除され、一覧から消える
```

**前週への依存関係:**
- Week 1: `Note.swift`, `AppError.swift`, `Router.swift`
- Week 2: `RecordingViewModel.stopAndSave()` からのキーワード抽出トリガー

---

### Week 4: 多言語対応 & ローカライズ

**実装するモジュール:** `Settings` 完全実装, `Localizable.xcstrings` 全キー, 全画面ローカライズ

#### 作成・更新ファイル一覧

| ファイルパス | 推定行数 | 説明 |
|------------|---------|------|
| `NoteChain/Resources/Localizable.xcstrings` | 400 | 全 UI キー × 3言語（en/ja/es） |
| `NoteChain/Features/Settings/SettingsView.swift` | 150 | 完全実装（Form + Section × 4） |
| `NoteChain/Features/Settings/SettingsViewModel.swift` | 100 | 完全実装（@AppStorage + weeklyCount リセット） |
| `NoteChain/Features/Settings/LanguagePickerView.swift` | 80 | フラグ + 言語名リスト |
| `NoteChain/Features/Recording/RecordingView.swift` | +20 | ハードコード文字列の LocalizedStringKey 化 |
| `NoteChain/Features/NotesList/NotesListView.swift` | +20 | ローカライズ適用 |
| `NoteChain/Features/NotesList/NoteDetailView.swift` | +20 | ローカライズ適用 |
| `NoteChain/Features/Subscription/PaywallView.swift` | +20 | ローカライズ適用 |
| `NoteChain/Features/Onboarding/OnboardingView.swift` | +20 | ローカライズ適用 |
| `NoteChain/Shared/Extensions/String+Localized.swift` | 30 | ローカライズ補助 |

**推定総行数:** 約 860 行

#### Localizable.xcstrings キー一覧（主要部分）

```
// 録音関連
"recording_tab" / "record_button" / "stop_button" / "saving_note"
"volatile_placeholder" / "final_placeholder"
"permission_denied_title" / "permission_denied_body" / "open_settings"

// ノート一覧
"notes_tab" / "search_notes" / "sort_newest" / "sort_oldest"
"sort_longest" / "sort_most_keywords" / "delete_note" / "delete_confirm"
"no_notes_title" / "no_notes_body" / "keywords_label"

// 設定
"settings_title" / "settings_tab" / "recording_language_section"
"ui_language_section" / "language_auto_detect" / "subscription_section"
"about_section" / "privacy_policy" / "version_label"

// サブスクリプション
"paywall_title" / "paywall_subtitle" / "trial_cta" / "monthly_plan"
"annual_plan" / "restore_purchases" / "weekly_limit_title" / "weekly_limit_body"

// エラー
"error_microphone_denied" / "error_speech_unavailable" / "error_save_failed"
"error_weekly_limit" / "recovery_open_settings" / "recovery_upgrade_pro"

// オンボーディング
"onboarding_permission_title" / "onboarding_language_title"
"onboarding_paywall_title" / "next_button" / "allow_button"
```

#### 受け入れ基準（Week 4）

```
Given: iOS Simulator の言語を日本語に設定
When:  アプリを起動してすべての画面を表示
Then:  ハードコード英語文字列が1つも存在しない（Strings lint ツールで確認）

Given: SettingsView で録音言語を「日本語」に変更
When:  録音を開始して日本語で話す
Then:  SpeechRecognitionService の locale が Locale(identifier: "ja-JP") に更新されており、
       日本語で文字起こしされる

Given: UI言語をスペイン語に変更
When:  アプリを再起動
Then:  TabBar・NavigationTitle・Button ラベルがすべてスペイン語で表示される
```

**前週への依存関係:**
- Week 1: `SettingsViewModel` のスケルトン
- Week 2: `RecordingViewModel` の `speechLocale` 参照
- Week 3: `NotesListView`, `NoteDetailView` の文字列

---

### Week 5: サブスクリプション & StoreKit 2

**実装するモジュール:** `Subscription` 完全実装, `Onboarding` 完全実装, トライアルリマインダー通知

#### 作成・更新ファイル一覧

| ファイルパス | 推定行数 | 説明 |
|------------|---------|------|
| `NoteChain/Features/Subscription/SubscriptionManager.swift` | 220 | StoreKit 2 完全実装 + ローカル通知スケジュール |
| `NoteChain/Features/Subscription/PaywallView.swift` | 200 | 完全 UI（機能リスト・プラン選択・CTA・復元） |
| `NoteChain/Features/Subscription/SubscriptionBadgeView.swift` | 50 | Pro/Free バッジ |
| `NoteChain/Features/Onboarding/OnboardingView.swift` | 150 | 完全実装（3ステップ PageView） |
| `NoteChain/Features/Onboarding/OnboardingViewModel.swift` | 80 | 完全実装 |
| `NoteChain/App/AppState.swift` | +30 | `isShowingPaywall` フラグ追加 |
| `NoteChain/App/ContentView.swift` | +20 | `.sheet(isPresented: $appState.isShowingPaywall)` 追加 |
| `NoteChain/Features/Recording/RecordingViewModel.swift` | +20 | 無料枠チェック + `showPaywall` フラグ連携 |
| `NoteChainTests/Features/Subscription/SubscriptionManagerTests.swift` | 150 | StoreKit Testing フレームワーク使用 |

**推定総行数:** 約 920 行

#### 主要実装詳細

```swift
// SubscriptionManager.scheduleTrialReminders() 実装例
private func scheduleTrialReminders() async {
    guard let expirationDate = subscriptionExpirationDate else { return }

    let center = UNUserNotificationCenter.current()
    guard await center.notificationSettings().authorizationStatus == .authorized else { return }

    // Day 2: 2日後
    scheduleNotification(
        id: "trial_day2",
        title: String(localized: "notification_trial_day2_title"),
        body: String(localized: "notification_trial_day2_body"),
        date: Calendar.current.date(byAdding: .day, value: -12, to: expirationDate)!
    )
    // Day 7: 7日経過（残り7日）
    scheduleNotification(id: "trial_day7", ..., date: ...)
    // Day 13: 残り1日
    scheduleNotification(id: "trial_day13", ..., date: ...)
}
```

#### 受け入れ基準（Week 5）

```
Given: hasCompletedOnboarding = false の初回起動
When:  アプリが表示される
Then:  OnboardingView (fullScreenCover) が表示され、
       ステップ1（マイク権限）→ステップ2（言語選択）→ステップ3（ペイウォール）の
       順でページ遷移する

Given: Sandbox テスト環境で年額プランを選択
When:  [14日間トライアル開始] をタップして購入フローを完了
Then:  isSubscribed = true になり、SubscriptionBadgeView が "Pro" を表示する

Given: 別デバイスで同じ Apple ID の有料ユーザー
When:  [購入情報を復元] をタップ
Then:  isSubscribed = true に更新される

Given: 無料ユーザーが今週すでに3件ノートを作成済み
When:  4件目の録音ボタンをタップ
Then:  PaywallView (sheet) が表示され、無料枠上限に達したことがメッセージで表示される

Given: PaywallView が表示されている
When:  画面右上の [×] ボタンをタップ
Then:  PaywallView が dismiss される（購入を強制しない）
```

**前週への依存関係:**
- Week 1: `AppState`, `ContentView`
- Week 2: `RecordingViewModel` の無料枠チェック連携
- Week 3: `NotesListView` から Paywall への遷移パス
- Week 4: `SettingsView` のサブスクリプションバッジ

---

### Week 6: 仕上げ・QA・App Store 申請

**実装するモジュール:** バグ修正, UIテスト実装, パフォーマンス最適化, 申請素材作成

#### 作成・更新ファイル一覧

| ファイルパス | 推定行数 | 説明 |
|------------|---------|------|
| `NoteChainUITests/RecordingFlowUITests.swift` | 120 | 録音→保存→一覧表示の E2E テスト |
| `NoteChainUITests/PaywallUITests.swift` | 80 | ペイウォール表示・キャンセルテスト |
| `NoteChainUITests/LanguageSwitchUITests.swift` | 80 | 言語切り替えテスト |
| `NoteChain/App/NoteChainApp.swift` | +20 | ModelContainer + SubscriptionManager 初期化整理 |
| `NoteChain/Features/Recording/RecordingView.swift` | +20 | アクセシビリティラベル追加 |
| `NoteChain/Features/NotesList/NotesListView.swift` | +20 | アクセシビリティ追加 |
| `NoteChain/Features/Subscription/PaywallView.swift` | +20 | アクセシビリティ・Dynamic Type 対応 |
| `docs/specs/recording.md` | 100 | 録音機能仕様書 |
| `docs/specs/keywords.md` | 80 | キーワード抽出仕様書 |
| `docs/specs/notes-list.md` | 80 | ノート一覧仕様書 |
| `docs/specs/settings.md` | 70 | 設定仕様書 |
| `docs/specs/subscription.md` | 90 | サブスクリプション仕様書 |

**推定総行数:** 約 780 行

#### QA チェックリスト（受け入れ基準）

```
Given: iPhone SE (3rd gen) / iPhone 15 Pro Max / iOS 17.0 / iOS 26+
When:  全機能を3言語（en/ja/es）でテスト
Then:  以下のすべてがパス:

  [パフォーマンス]
  ・アプリ起動時間 < 2秒（コールドスタート）
  ・録音開始遅延 < 500ms
  ・キーワード抽出（100語テキスト）< 1秒
  ・ノート検索（1,000件）< 500ms
  ・メモリ使用量（アイドル）< 50MB

  [音声認識]
  ・iOS 26+ で SpeechAnalyzer が使用されている（ログ確認）
  ・iOS 17.0 で LegacySpeechService が使用されている
  ・30秒録音で volatile/final の色分けが正しい

  [サブスクリプション]
  ・初回起動でオンボーディング→ペイウォールが表示される
  ・週3件制限が正しくカウントされる
  ・購入後にアプリ再起動しても isSubscribed = true

  [プライバシー]
  ・Charles Proxy でネットワーク通信がないことを確認
  ・録音停止後にマイクの使用インジケーターが消えることを確認

Given: すべてのユニットテストとUIテストが実行完了
When:  XcodeBuildMCP の /test コマンドで確認
Then:  テスト成功率 100%、カバレッジ ViewModel 80%+ を達成

Given: App Store Connect に申請素材が準備済み
When:  Xcode から Archive して申請
Then:  ビルドが成功し、App Store Connect にアップロードされる
```

**前週への依存関係:**
- Week 1–5: 全機能実装済みであること

---

## 7. 依存関係マトリクス

```
Feature/Module         | Note | AppError | Router | SpeechSvc | KeywordExt | SubscriptionMgr | SettingsVM
-----------------------|------|----------|--------|-----------|------------|-----------------|----------
Recording              |  ✅  |    ✅    |   ✅  |     ✅    |     ✅     |       ✅        |    ✅
Keywords               |  ✅  |    -     |   -   |     -     |     -      |       -         |    -
NotesList              |  ✅  |    ✅    |   ✅  |     -     |     ✅     |       -         |    -
Settings               |  -   |    -     |   ✅  |     -     |     -      |       ✅        |    -
Subscription           |  -   |    ✅    |   -   |     -     |     -      |       -         |    ✅
Onboarding             |  -   |    ✅    |   -   |     -     |     -      |       ✅        |    ✅

依存方向: 全 Feature → Shared のみ（Features 間の直接依存なし）
Feature 間連携: Environment による SubscriptionManager, SettingsViewModel の共有
```

---

## 8. Swift 6 Concurrency 設計方針

### Actor 分離モデル

```
MainActor（UIスレッド）
├── RecordingViewModel        @MainActor @Observable
├── NotesListViewModel        @MainActor @Observable
├── NoteDetailViewModel       @MainActor @Observable
├── SettingsViewModel         @MainActor @Observable
├── SubscriptionManager       @MainActor @Observable
├── OnboardingViewModel       @MainActor @Observable
└── Router                    @MainActor @Observable

非同期処理（Task / Task.detached）
├── SpeechAnalyzerService.startRecognition() → AsyncThrowingStream
├── LegacySpeechService.startRecognition()  → AsyncThrowingStream
├── NLTaggerKeywordExtractor.extractAsync() → Task.detached (CPU-bound)
└── SubscriptionManager.observeTransactionUpdates() → Task.detached

ModelActor（将来: バックグラウンドSwiftData書き込み）
└── BackgroundNoteWriter（v1.1 以降: 大量インポート時）
```

### 禁止パターン

```swift
// ❌ 禁止: DispatchQueue の使用
DispatchQueue.global().async { ... }

// ❌ 禁止: @Published / @ObservedObject
@Published var isRecording = false  // @Observable を使う

// ❌ 禁止: nonisolated(unsafe)
nonisolated(unsafe) var sharedState = ...

// ❌ 禁止: 無制御な @unchecked Sendable
final class MyClass: @unchecked Sendable { ... }  // LegacySpeechService のみ許可

// ✅ 推奨: @MainActor ViewModel + Task
@MainActor @Observable final class MyViewModel {
    func load() async {
        let result = await someService.fetch()  // バックグラウンドで実行
        self.data = result                        // @MainActor で自動的に Main スレッドに戻る
    }
}
```

### AsyncThrowingStream のライフサイクル管理

```swift
// RecordingViewModel での正しいTask管理
@MainActor
@Observable
final class RecordingViewModel {
    private var recognitionTask: Task<Void, Never>?

    func startRecording(locale: Locale) async {
        // 既存タスクをキャンセル
        recognitionTask?.cancel()

        recognitionTask = Task {
            do {
                for try await result in speechService.startRecognition(locale: locale) {
                    guard !Task.isCancelled else { break }
                    // UI 更新（@MainActor なので安全）
                    updateTranscript(result)
                }
            } catch is CancellationError {
                // キャンセルは正常終了
            } catch {
                errorMessage = AppError.recognitionTaskFailed(error).errorDescription
            }
        }
    }

    func stopRecording() async {
        recognitionTask?.cancel()
        recognitionTask = nil
        await speechService.stopRecognition()
    }

    // View の .onDisappear や deinit でも必ず呼ぶ
    deinit {
        recognitionTask?.cancel()
    }
}
```

---

## Appendix: NoteChainApp.swift エントリポイント設計

```swift
// NoteChain/App/NoteChainApp.swift
import SwiftUI
import SwiftData

@main
struct NoteChainApp: App {
    @State private var appState = AppState()
    @State private var subscriptionManager = SubscriptionManager()
    @State private var router = Router()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(subscriptionManager)
                .environment(router)
                .modelContainer(for: Note.self, inMemory: false) { result in
                    if case .failure(let error) = result {
                        // 起動時の SwiftData エラーは致命的
                        fatalError("Failed to initialize ModelContainer: \(error)")
                    }
                }
                .task {
                    await subscriptionManager.initialize()
                }
        }
    }
}

// NoteChain/App/AppState.swift
@MainActor
@Observable
final class AppState {
    var isShowingPaywall: Bool = false
    var isShowingOnboarding: Bool = false

    @AppStorage("hasCompletedOnboarding")
    var hasCompletedOnboarding: Bool = false

    init() {
        isShowingOnboarding = !hasCompletedOnboarding
    }
}
```

---

*設計書バージョン 1.0 — NoteChain AI駆動開発プロジェクト*  
*Claude Code + XcodeBuildMCP 最適化済み*  
*最終更新: 2026-04-01*
