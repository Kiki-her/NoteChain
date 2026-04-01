# NoteChain - プロダクト要件定義書（PRD）

**バージョン:** 1.1（AI駆動開発最適化版）
**日付:** 2026-04-01
**ステータス:** AI 駆動開発の準備完了
**ターゲットローンチ:** 2026-05-15（6週間以内）
**主担当開発:** Claude Code ＋ 人間レビュー
**変更履歴:**
| バージョン | 日付 | 変更内容 |
|-----------|------|---------|
| 1.0 | 2026-04-01 | 初版作成 |
| 1.1 | 2026-04-01 | SpeechAnalyzer採用、@Observable統一、Vertical Slice化、NLTagger MVP化、AI駆動開発基盤追加、受け入れ基準をGWT形式に変更 |

---

## エグゼクティブサマリー

NoteChain は、プライバシー優先の AI 搭載ボイスメモアプリです。音声をリアルタイムで文字起こしし、自動でキーワード抽出を行い、オンデバイス機械学習によってノートを知的に整理します。
ターゲットユーザーは、学生・ビジネスパーソン・ジャーナリスト・リモートワーカーなど、「入力の手間なく素早くアイデアを残したい」人たちです。

**コアバリュー・プロポジション:**

🎙️ 即時ボイス → テキスト: 話すだけ → 数秒で自動テキスト化
🏷️ スマート整理: AI が自動でキーワード抽出 & タグ付け
🔍 高速検索: コンテンツ・日付・自動生成キーワードでノート検索
🔒 プライバシーファースト: 100% オンデバイス処理。クラウドバックエンド不要。
🌍 多言語対応: リリース時から英語・日本語・スペイン語をサポート

**財務目標:**

- Apple Developer Program 年会費: $99（回収目標：初月）
- 初期 ARPU 目標: アクティブ有料ユーザー 1人あたり $20–25 / 年（RLTV）
- 損益分岐ユーザー数: 月間有料ユーザー 5–10 人
- 1年目の保守的見積もり: 有料ユーザー 150–200 人 → 年間収益 $3,000–5,000

---

## 市場機会

### TAM & 市場データ（2026）

| 指標 | 値 | 出典 |
|------|-----|------|
| 教育系アプリ市場（世界） | $50B+ | Business of Apps 2026 |
| 生産性アプリ RLTV（年間） | $30+ | RevenueCat 2026 State Report |
| 月間トライアル転換率 | 14–17% | Adapty 2026 |
| 最も高い転換率のトライアル期間 | 14–17日 | SOIS 2026（3日間より 70% 良い） |
| 伸びが速い市場 | 日本・メキシコ・トルコ | Adapty 2026 |

### 競合状況

| 競合 | 価格 | 弱み | NoteChain の優位性 |
|------|------|------|-------------------|
| Otter.ai | $10/月 | クラウド依存・プライバシー懸念 | オフライン優先・より安価 |
| Apple ボイスメモ | 無料 | 文字起こしなし・整理機能なし | スマートタグ・文字起こしあり |
| Notion AI | $10+ CAP | 多機能すぎ・音声には重い | 音声特化・軽量・高速 |
| Speeko | $3.99/月 | スピーチコーチ専用（メモ用途ではない） | 純粋なノート用途に特化 |

**NoteChain のポジション:**

- サブカテゴリ: 軽量でプライバシーを重視した文字起こし付きノートアプリ
- 価格: $3.99/月（$29.99/年） ← Otter より安く、無料アプリより上
- 差別化要因: 完全オフライン・バックエンドコストなし・初日から多言語対応

---

## プロダクトビジョン & ゴール

### フェーズ 1: MVP（2026-05-15） - 6週間

コアな文字起こし + タグ付けに集中した、最小限だが洗練されたバージョンをローンチ。

**中核機能:**

- 音声録音とリアルタイム文字起こし（SpeechAnalyzer / SFSpeechRecognizer フォールバック）
- NaturalLanguage フレームワークによる自動キーワード抽出
- メタデータ付き検索可能なノート一覧
- 多言語対応（英語 / 日本語 / スペイン語）
- サブスクリプションペイウォール（14日間無料トライアル）

**スコープ外（MVP では実装しない）:**

- 共有 / コラボレーション
- クラウド同期（v1.1 以降）
- Web アプリ（v2.0）
- 高度な分析機能
- Core ML カスタムモデルによるキーワード抽出（v1.1 以降）

### 成功指標（フェーズ 1）

| 指標 | 目標 | 期限 |
|------|------|------|
| App Store 審査 | ✅ 承認 | 35日目 |
| 初期インストール数 | 500–1,000 | 8週目 |
| ダウンロード→トライアル率（D14） | 10–15% | 4週目 |
| トライアル→有料転換率 | 15–25% | 6週目 |
| Day 1 リテンション | >40% | 継続的 |
| 有料ユーザー数 | 5–8 | 6週目 |

### フェーズ 2: 成長（2026-06-15 以降）

- Core ML カスタムモデルによる高精度キーワード抽出
- アプリ内アナリティクスダッシュボード
- iCloud 同期（オプション・有料ユーザー向け）
- Android 版（React Native）
- 高度な検索・フィルタリング

### フェーズ 3: 収益最大化（2026-Q3）

- プレミアムティア（$9.99/月）
- 外部連携用 API
- B2B ライセンス（大学・企業向け）

---

## 技術アーキテクチャ

### 技術スタック

| レイヤー | 技術 | 選定理由 |
|---------|------|---------|
| UI | SwiftUI (100% 宣言的) | AIが95%以上の精度で生成可能 |
| 状態管理 | @Observable + MVVM | Swift 5.9+ 推奨。@Published不要でボイラープレート削減 |
| ナビゲーション | NavigationStack + Router パターン | 型安全な画面遷移。AIが一貫したパターンで生成しやすい |
| データ永続化 | SwiftData (iOS 17+) | 宣言的スキーマ。AI が初回から適切に生成可能 |
| 音声キャプチャ | AVAudioEngine | 低レベルオーディオ入力。SpeechAnalyzer / SFSpeechRecognizerへの供給用 |
| 音声認識（主） | SpeechAnalyzer (iOS 26+) | WWDC25発表の次世代API。長時間音声対応・完全オンデバイス・AsyncSequenceネイティブ |
| 音声認識（フォールバック） | SFSpeechRecognizer (iOS 17+) | iOS 26未満デバイスへのフォールバック |
| キーワード抽出（MVP） | NaturalLanguage (NLTagger) | 追加モデル不要。名詞・固有名詞・頻出語をオンデバイスで抽出 |
| キーワード抽出（v1.1+） | Core ML (Create ML) | カスタム学習モデルによる高精度抽出 |
| 課金 | StoreKit 2 | ネイティブ。依存ライブラリ不要 |
| 言語検出 | NaturalLanguage (NLLanguageRecognizer) | 録音言語の自動検出 |
| アナリティクス | TelemetryDeck（任意） | プライバシーファースト。軽量 |

### 対応バージョン

| 項目 | 要件 |
|------|------|
| 最低iOS | 17.0（SwiftData 必須） |
| 推奨iOS | 26+（SpeechAnalyzer フル活用） |
| Swift | 6.0（Strict Concurrency 有効） |
| Xcode | 16.0+ |
| デバイス | iPhone SE (3rd gen) 以降 |

### アーキテクチャ図

```
┌─────────────────────────────────────────────────────────┐
│                    iOS アプリレイヤー                    │
├─────────────────────────────────────────────────────────┤
│  UI フレームワーク:      SwiftUI（100% 宣言的）          │
│  状態管理:               @Observable + MVVM              │
│  ナビゲーション:         NavigationStack + Router         │
│  ローカルストレージ:     SwiftData                       │
│  音声キャプチャ:         AVAudioEngine                   │
│  課金:                   StoreKit 2                      │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│              オンデバイス処理レイヤー                    │
├─────────────────────────────────────────────────────────┤
│  音声→テキスト（主）:    SpeechAnalyzer (iOS 26+)       │
│  音声→テキスト（FB）:    SFSpeechRecognizer (iOS 17+)   │
│  キーワード抽出（MVP）:  NaturalLanguage (NLTagger)     │
│  キーワード抽出（v1.1）: Core ML (Create ML)            │
│  言語検出:               NLLanguageRecognizer            │
│  テキスト処理:           Foundation                      │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│            オプションクラウドレイヤー（v1.1+）          │
├─────────────────────────────────────────────────────────┤
│  同期:                   CloudKit                       │
│  分析:                   TelemetryDeck                   │
│  ※ MVP では不要：ローカルファースト構成                  │
└─────────────────────────────────────────────────────────┘
```

### Concurrency 方針（Swift 6 Strict Concurrency）

- ALWAYS: ViewModel は `@MainActor` で隔離する
- ALWAYS: バックグラウンドI/O（SwiftData書き込み等）は `ModelActor` を使用する
- NEVER: `@unchecked Sendable` や `nonisolated(unsafe)` を安易に使わない
- ALWAYS: `async/await` を使用。Combine / DispatchQueue.global() は使わない
- ALWAYS: `Task { }` の戻り値やキャンセルを適切に管理する

### プロジェクト構造（Vertical Slice アーキテクチャ）

```
NoteChain/
├── CLAUDE.md                              # AI駆動開発のメイン指示書
├── AGENTS.md                              # 他AIツール互換（CLAUDe.mdをインポート）
├── .claude/
│   ├── CLAUDE.md                          # .claude ディレクトリ概要
│   ├── rules/                             # パス別・レイヤー別ルール
│   │   ├── general.md                     #   全体ルール（常時ロード）
│   │   ├── security.md                    #   セキュリティ禁則事項（常時ロード）
│   │   ├── swift-style.md                 #   Swift 6 / Concurrency 規約（*.swift）
│   │   ├── swiftui.md                     #   SwiftUI固有パターン（*View.swift）
│   │   ├── swiftdata.md                   #   SwiftData / @Model 規約
│   │   ├── testing.md                     #   Swift Testing 規約（*Tests.swift）
│   │   └── subscription.md               #   StoreKit 2 規約
│   ├── skills/                            # Agent Skills
│   │   ├── implement-feature/
│   │   │   └── SKILL.md
│   │   ├── code-review/
│   │   │   └── SKILL.md
│   │   └── test-generator/
│   │       └── SKILL.md
│   ├── commands/                          # スラッシュコマンド
│   │   ├── build.md
│   │   ├── test.md
│   │   ├── generate-spec.md
│   │   ├── generate-tasks.md
│   │   └── implement-feature.md
│   └── settings.json                      # Claude Code プロジェクト設定
├── .mcp.json                              # XcodeBuildMCP 設定
├── docs/
│   ├── PRD.md                             # 本ドキュメント
│   ├── ARCHITECTURE.md                    # 技術設計書
│   └── specs/                             # 機能仕様書
│       ├── template.md                    #   テンプレート
│       ├── recording.md                   #   録音 & 文字起こし仕様
│       ├── keywords.md                    #   キーワード抽出仕様
│       ├── notes-list.md                  #   ノート一覧仕様
│       ├── settings.md                    #   設定 & 多言語仕様
│       └── subscription.md               #   サブスクリプション仕様
├── NoteChain/
│   ├── App/
│   │   ├── NoteChainApp.swift             # @main エントリポイント
│   │   ├── ContentView.swift              # ルートTabView + Router
│   │   └── AppState.swift                 # アプリ全体の状態
│   ├── Features/
│   │   ├── Recording/                     # 機能1: 音声録音 & 文字起こし
│   │   │   ├── RecordingView.swift
│   │   │   ├── RecordingViewModel.swift
│   │   │   ├── RecordingManager.swift     # AVAudioEngine ライフサイクル管理
│   │   │   └── README.md                  # モジュール説明（AIコンテキスト）
│   │   ├── NotesList/                     # 機能3: ノート一覧 & 検索
│   │   │   ├── NotesListView.swift
│   │   │   ├── NotesListViewModel.swift
│   │   │   ├── NoteRowView.swift
│   │   │   ├── NoteDetailView.swift
│   │   │   ├── NoteDetailViewModel.swift
│   │   │   └── README.md
│   │   ├── Keywords/                      # 機能2: キーワード抽出
│   │   │   ├── KeywordExtractor.swift     # NLTagger ベース実装
│   │   │   ├── KeywordBadgeView.swift
│   │   │   └── README.md
│   │   ├── Settings/                      # 機能4: 設定 & 多言語
│   │   │   ├── SettingsView.swift
│   │   │   ├── SettingsViewModel.swift
│   │   │   ├── LanguagePickerView.swift
│   │   │   └── README.md
│   │   ├── Subscription/                 # 機能5: サブスクリプション
│   │   │   ├── PaywallView.swift
│   │   │   ├── SubscriptionManager.swift
│   │   │   ├── SubscriptionBadgeView.swift
│   │   │   └── README.md
│   │   └── Onboarding/                   # オンボーディング
│   │       ├── OnboardingView.swift
│   │       └── README.md
│   ├── Shared/
│   │   ├── Models/
│   │   │   ├── Note.swift                 # @Model SwiftData エンティティ
│   │   │   └── AppError.swift             # アプリ共通エラー型
│   │   ├── Navigation/
│   │   │   └── Router.swift               # NavigationStack + Route enum
│   │   ├── Services/
│   │   │   └── SpeechRecognitionService.swift  # プロトコル + 2実装
│   │   ├── Extensions/
│   │   │   └── Date+Formatting.swift
│   │   └── Components/                    # 再利用可能UIコンポーネント
│   │       └── LoadingOverlay.swift
│   └── Resources/
│       ├── Localizable.xcstrings          # 多言語文字列（en, ja, es）
│       └── Assets.xcassets
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
    └── RecordingFlowUITests.swift
```

**この構造が AI 駆動開発に最適な理由:**

- **Vertical Slice**: 各 Feature ディレクトリが自己完結。AIエージェントが `Recording/` だけを読めば録音機能を完全に理解・実装できる
- **README.md per Feature**: AIがモジュールのコンテキストを即座に把握できる
- **テストの共配置**: `NoteChainTests/Features/Recording/` が `Features/Recording/` と対応。テスト作成時に関連コードだけを参照
- **.claude/rules/ のパス限定**: `*View.swift` 編集時にはSwiftUIルールだけがロードされ、コンテキスト汚染を防止

---

## コア機能 & 技術仕様

### 機能 1: 音声録音 & リアルタイム文字起こし

**ユーザーフロー:**

```
ユーザーがアプリを開く
  ↓
「録音」ボタンをタップ
  ↓
SpeechAnalyzer（またはSFSpeechRecognizer）がリスニング開始
  ↓
volatile results（途中経過）をリアルタイムで薄紫色テキスト表示
  ↓
final results（確定テキスト）を黒色テキストで順次確定
  ↓
「停止」をタップ
  ↓
最終文字起こしを SwiftData に Note として保存
  ↓
キーワード抽出をトリガー
  ↓
ノート一覧に表示
```

**音声認識の二層アーキテクチャ:**

```swift
// SpeechRecognitionService プロトコル（Shared/Services/）
// 2つの実装を透過的に切り替え

protocol SpeechRecognitionServiceProtocol: Sendable {
    func startRecognition(locale: Locale) -> AsyncThrowingStream<TranscriptionResult, Error>
    func stopRecognition() async
    var isAvailable: Bool { get async }
}

struct TranscriptionResult: Sendable {
    let text: String
    let isFinal: Bool       // volatile vs final
    let confidence: Double?
}

// ファクトリで自動切り替え
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

**SpeechAnalyzer 実装（iOS 26+）:**

```swift
import Speech

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

                // volatile + final results を AsyncSequence で配信
                for try await result in transcriber.results {
                    continuation.yield(TranscriptionResult(
                        text: String(result.text.characters),
                        isFinal: result.isFinal,
                        confidence: nil
                    ))
                }
                continuation.finish()
            }
        }
    }

    func stopRecognition() async {
        try? await analyzer?.finalizeAndFinishThroughEndOfInput()
    }

    var isAvailable: Bool {
        get async { true } // SpeechAnalyzer はオンデバイス前提
    }
}
```

**SFSpeechRecognizer フォールバック（iOS 17–25）:**

```swift
final class LegacySpeechService: NSObject, SpeechRecognitionServiceProtocol {
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func startRecognition(locale: Locale) -> AsyncThrowingStream<TranscriptionResult, Error> {
        AsyncThrowingStream { continuation in
            let speechRecognizer = SFSpeechRecognizer(locale: locale)

            guard let speechRecognizer, speechRecognizer.isAvailable else {
                continuation.finish(throwing: AppError.speechRecognitionUnavailable)
                return
            }

            // オンデバイス認識を強制（プライバシー）
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.requiresOnDeviceRecognition = true
            request.shouldReportPartialResults = true
            self.recognitionRequest = request

            self.recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
                if let result {
                    continuation.yield(TranscriptionResult(
                        text: result.bestTranscription.formattedString,
                        isFinal: result.isFinal,
                        confidence: Double(result.bestTranscription.segments.last?.confidence ?? 0)
                    ))
                }
                if let error {
                    continuation.finish(throwing: error)
                }
            }

            // AVAudioEngine セットアップ
            let inputNode = self.audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                request.append(buffer)
            }

            do {
                try self.audioEngine.start()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }

    func stopRecognition() async {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
    }

    var isAvailable: Bool {
        get async {
            SFSpeechRecognizer()?.isAvailable ?? false
        }
    }
}
```

**対応言語:**

🇺🇸 英語（US, UK など）
🇯🇵 日本語
🇪🇸 スペイン語

**精度（目安）:**

- SpeechAnalyzer (iOS 26+): 90–95%（Whisper 同等。長時間音声でも劣化しにくい）
- SFSpeechRecognizer (iOS 17+): 85–92%（音質に依存）
- ユーザーは 1タップで編集モードに入り、文字起こしを手動修正可能

**ストレージモデル（Note）:**

```swift
import SwiftData
import Foundation

@Model
final class Note {
    @Attribute(.unique) var id: UUID
    var audioFileURL: URL?
    var transcript: String
    var keywords: [String]
    var keywordConfidences: [String: Double]
    var createdAt: Date
    var updatedAt: Date
    var duration: TimeInterval
    var languageCode: String
    var isFavorite: Bool

    var wordCount: Int {
        transcript.split(separator: " ").count
    }

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
```

**必要な権限:**

- `NSMicrophoneUsageDescription`: 「音声メモの録音のためにマイクを使用します」
- `NSSpeechRecognitionUsageDescription`: 「音声をテキストに変換するために音声認識を使用します」

**受け入れ基準（Given-When-Then）:**

- Given: アプリがマイク権限を持っている / When: 録音ボタンをタップ / Then: 録音が開始され、500ms以内にリアルタイムでvolatileテキストが薄紫色で表示される
- Given: 録音中 / When: 停止ボタンをタップ / Then: 最終テキストがSwiftDataにNoteとして保存され、ノート一覧に表示される
- Given: マイク権限がない / When: 録音ボタンをタップ / Then: 権限リクエストダイアログが表示される
- Given: マイク権限を拒否 / When: 録音画面を表示 / Then: 「設定で権限を変更」ボタンが表示され、タップでiOS設定に遷移する
- Given: 録音中に電話着信 / When: オーディオセッションが中断される / Then: 録音が一時停止し、中断終了後に復帰可能な状態になる
- Given: 設定で日本語を選択 / When: 日本語で話す / Then: 日本語で文字起こしされる
- Given: iOS 26+ デバイス / When: 録音を開始 / Then: SpeechAnalyzer が使用される
- Given: iOS 17-25 デバイス / When: 録音を開始 / Then: SFSpeechRecognizer フォールバックが使用される

---

### 機能 2: キーワード抽出（NaturalLanguage ベース）

**MVP 実装（NLTagger）:**

- NLTagger による品詞タグ付けで名詞・固有名詞を抽出
- 出現頻度によるスコアリングで重要語句をランキング
- NLLanguageRecognizer で言語自動検出 → 言語別処理
- 追加モデル不要。NaturalLanguage フレームワークのみで完結
- 英語・日本語・スペイン語すべてで動作

**抽出ロジック:**

```swift
import NaturalLanguage

protocol KeywordExtractorProtocol {
    func extract(from text: String, maxKeywords: Int) -> [(keyword: String, confidence: Double)]
}

final class NLTaggerKeywordExtractor: KeywordExtractorProtocol {
    func extract(from text: String, maxKeywords: Int = 5) -> [(keyword: String, confidence: Double)] {
        // 1. 言語検出
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        let language = recognizer.dominantLanguage ?? .english

        // 2. NLTagger で品詞タグ付け
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
        tagger.string = text
        tagger.setLanguage(language, range: text.startIndex..<text.endIndex)

        var wordFrequency: [String: Int] = [:]
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]

        // 3. 名詞・固有名詞を収集
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: options
        ) { tag, tokenRange in
            if let tag, [.noun, .personalName, .placeName, .organizationName].contains(tag) {
                let word = String(text[tokenRange]).lowercased()
                if word.count > 1 && !Self.stopWords.contains(word) {
                    wordFrequency[word, default: 0] += 1
                }
            }
            return true
        }

        // 4. 頻度でスコアリング（正規化）
        let maxFreq = Double(wordFrequency.values.max() ?? 1)
        return wordFrequency
            .map { (keyword: $0.key, confidence: Double($0.value) / maxFreq) }
            .sorted { $0.confidence > $1.confidence }
            .prefix(maxKeywords)
            .map { $0 }
    }

    private static let stopWords: Set<String> = [
        // English
        "the", "a", "an", "is", "are", "was", "were", "be", "been",
        "have", "has", "had", "do", "does", "did", "will", "would",
        "could", "should", "may", "might", "shall", "can", "this",
        "that", "these", "those", "i", "you", "he", "she", "it",
        "we", "they", "my", "your", "his", "her", "its", "our",
        // 日本語
        "の", "に", "は", "を", "た", "が", "で", "て", "と", "し",
        "れ", "さ", "ある", "いる", "する", "も", "な", "こと", "もの",
        // Spanish
        "el", "la", "los", "las", "un", "una", "de", "en", "que",
        "y", "a", "por", "con", "para", "es", "no", "se", "del"
    ]
}
```

**抽出結果の例:**

```
Transcript:
"Had a meeting with the marketing team about Q2 planning.
They want to increase social media spend by 30% and launch
a new campaign targeting Gen Z."

→ 自動抽出されるキーワード:
[
  ("marketing", 0.92),
  ("meeting", 0.85),
  ("campaign", 0.78),
  ("planning", 0.71),
  ("media", 0.64)
]
```

**v1.1 以降の拡張（Core ML）:**

- Create ML で学習したカスタムモデルに置き換え
- `KeywordExtractorProtocol` の別実装として追加（ストラテジーパターン）
- 文脈依存の抽出で精度向上

**UX 仕様:**

- キーワードはノートタイトル下にバッジとして自動表示
- ユーザーはキーワードの追加 / 削除が可能
- キーワードタップで、そのタグを持つノートにフィルタリング

**受け入れ基準（Given-When-Then）:**

- Given: 100語の英語テキスト / When: キーワード抽出を実行 / Then: 1秒以内に3-5個のキーワードが信頼度スコア付きで返される
- Given: 日本語テキスト / When: キーワード抽出を実行 / Then: 日本語の名詞が正しく抽出される
- Given: 抽出されたキーワード / When: ノート詳細画面を表示 / Then: キーワードがバッジとして表示される
- Given: 表示されたキーワードバッジ / When: バッジをタップ / Then: そのキーワードを持つノート一覧にフィルタリングされる
- Given: ユーザーが手動でキーワードを追加 / When: 保存 / Then: キーワード一覧に追加され、検索で発見可能になる
- Given: ネットワーク未接続状態 / When: キーワード抽出を実行 / Then: 正常に動作する（完全オンデバイス）

---

### 機能 3: 検索可能なノート一覧 & 整理

**一覧ビュー:**

```
[タブバー: すべて | 日付別 | 言語別]

┌──────────────────────────────────────┐
│ 🔍 検索（キーワード / 日付でフィルタ）│
├──────────────────────────────────────┤
│📅 今日                               │
│ • 「Q2 マーケティング計画」          │
│   #meeting #marketing #Q2planning    │
│   2 分前 | 3:45                      │
│                                      │
│ • 「プロダクトロードマップ議論」      │
│   #product #roadmap #planning        │
│   45 分前 | 12:30                    │
├──────────────────────────────────────┤
│📅 昨日                               │
│ • 「デザインチームとのランチメモ」    │
│   #design #meeting #feedback         │
│   昨日 | 8:12                        │
└──────────────────────────────────────┘
```

**ソートオプション:**

- 新しい順（デフォルト）
- 古い順
- 録音時間が長い順
- キーワード数が多い順

**検索ロジック:**

```swift
@MainActor
@Observable
final class NotesListViewModel {
    var searchText: String = ""
    var sortOrder: SortOrder = .newestFirst
    var languageFilter: String? = nil

    private let modelContext: ModelContext

    var filteredNotes: [Note] {
        var descriptor = FetchDescriptor<Note>(
            sortBy: [sortOrder.sortDescriptor]
        )

        let notes = (try? modelContext.fetch(descriptor)) ?? []

        if searchText.isEmpty && languageFilter == nil {
            return notes
        }

        return notes.filter { note in
            let matchesSearch = searchText.isEmpty ||
                note.transcript.localizedCaseInsensitiveContains(searchText) ||
                note.keywords.contains { $0.localizedCaseInsensitiveContains(searchText) }
            let matchesLanguage = languageFilter == nil ||
                note.languageCode == languageFilter
            return matchesSearch && matchesLanguage
        }
    }

    enum SortOrder {
        case newestFirst, oldestFirst, longestFirst, mostKeywords

        var sortDescriptor: SortDescriptor<Note> {
            switch self {
            case .newestFirst: SortDescriptor(\.createdAt, order: .reverse)
            case .oldestFirst: SortDescriptor(\.createdAt, order: .forward)
            case .longestFirst: SortDescriptor(\.duration, order: .reverse)
            case .mostKeywords: SortDescriptor(\.createdAt, order: .reverse) // SwiftDataではkeywords.countでソート不可のためフォールバック
            }
        }
    }
}
```

**クエリ特性:**

- すべて SwiftData によるローカルクエリ
- ネットワーク通信なし
- ノート 1,000 件規模でも <500ms でフィルタ完了

**受け入れ基準（Given-When-Then）:**

- Given: 10件のノートがある / When: ノート一覧画面を表示 / Then: 新しい順で全ノートが表示される
- Given: ノート一覧画面 / When: 「meeting」と検索 / Then: transcript または keywords に「meeting」を含むノートのみ表示される
- Given: 検索結果がある / When: ソートを「録音時間が長い順」に変更 / Then: 表示順が duration 降順に変わる
- Given: ノート一覧 / When: ノートをスワイプ削除 / Then: SwiftData から削除され一覧から消える
- Given: 1,000件のノート / When: 検索を実行 / Then: 500ms以内に結果が表示される

---

### 機能 4: 多言語サポート

**言語設定 UI:**

```
┌──────────────────────────────┐
│ 設定                         │
├──────────────────────────────┤
│ 録音言語:                    │
│ ○ English (US)               │
│ ○ 日本語（Japanese）         │
│ ○ Español (Spanish)          │
│ ○ 自動検出                   │
│                              │
│ UI 言語:                     │
│ ○ English                    │
│ ○ 日本語                     │
│ ○ Español                    │
│ ○ システムデフォルト        │
└──────────────────────────────┘
```

**実装:**

```swift
@MainActor
@Observable
final class SettingsViewModel {
    @AppStorage("recordingLanguage") var recordingLanguage = "en-US"
    @AppStorage("uiLanguage") var uiLanguage = "system"
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false

    var speechLocale: Locale {
        Locale(identifier: recordingLanguage)
    }

    static let supportedRecordingLanguages: [(code: String, name: String, flag: String)] = [
        ("en-US", "English (US)", "🇺🇸"),
        ("ja-JP", "日本語", "🇯🇵"),
        ("es-ES", "Español", "🇪🇸"),
    ]

    static let supportedUILanguages: [(code: String, name: String)] = [
        ("system", "System Default"),
        ("en", "English"),
        ("ja", "日本語"),
        ("es", "Español"),
    ]
}
```

**ローカライズキー例（Localizable.xcstrings）:**

```
English:
"recording_button" = "Record Note"
"stop_button" = "Stop"
"keywords_label" = "Keywords"
"notes_tab" = "Notes"
"settings_tab" = "Settings"

Japanese:
"recording_button" = "メモを記録"
"stop_button" = "停止"
"keywords_label" = "キーワード"
"notes_tab" = "ノート"
"settings_tab" = "設定"

Spanish:
"recording_button" = "Grabar Nota"
"stop_button" = "Parar"
"keywords_label" = "Palabras clave"
"notes_tab" = "Notas"
"settings_tab" = "Configuración"
```

**受け入れ基準（Given-When-Then）:**

- Given: 設定で録音言語を日本語に変更 / When: 録音を開始して日本語で話す / Then: 日本語で文字起こしされる
- Given: 3言語それぞれ / When: すべてのUI画面を表示 / Then: ハードコード文字列がなく全テキストがローカライズされている
- Given: UI言語をスペイン語に変更 / When: アプリを再起動 / Then: 全画面がスペイン語で表示される

---

### 機能 5: サブスクリプション & マネタイズ（StoreKit 2）

**ペイウォールデザイン:**

```
┌──────────────────────────────────────────────┐
│  NoteChain Premium                          │
├──────────────────────────────────────────────┤
│  無制限のボイスノート                       │
│  ✓ AI キーワード抽出                        │
│  ✓ フルテキスト検索                        │
│  ✓ PDF 形式でのエクスポート                │
│  ✓ iCloud 同期（近日対応）                  │
│                                              │
│  おすすめ → [年額 $29.99]                    │
│  または [月額 $3.99]                         │
│                                              │
│  [14日間の無料トライアルを開始]             │
│  トライアル終了後、自動的に課金されます     │
│  [購入情報を復元]                            │
│                                              │
│  プライバシーポリシー | 利用規約             │
└──────────────────────────────────────────────┘
```

**価格戦略:**

| プラン | 月額 | 年額 | 割引率 | ターゲットユーザー |
|-------|------|------|--------|-----------------|
| Free | $0 | $0 | - | カジュアル利用（週 3 ノートまで） |
| Pro | $3.99 | $29.99 | 37% | 毎日利用するユーザー |

**無料プラン制限:**

- 1週間あたり 3 件までボイスノート作成可
- キーワード抽出なし
- ノートは 30日後に自動削除
- 基本検索のみ

**Pro（有料）プラン:**

- 無制限ノート
- AI キーワード抽出
- フルテキスト検索
- ノートの無期限保存
- PDF / テキストへエクスポート
- 広告なし

**StoreKit 2 実装:**

```swift
import StoreKit
import SwiftUI

@MainActor
@Observable
final class SubscriptionManager {
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isSubscribed: Bool = false
    var isLoading: Bool = false
    var errorMessage: String? = nil

    private var transactionListener: Task<Void, Never>?

    private static let productIDs = [
        "com.yourcompany.notechain.pro_monthly",
        "com.yourcompany.notechain.pro_annual"
    ]

    func initialize() async {
        transactionListener = observeTransactionUpdates()
        await fetchProducts()
        await updatePurchasedProducts()
    }

    func fetchProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: Self.productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try verification.payloadValue
            purchasedProductIDs.insert(product.id)
            await transaction.finish()
            isSubscribed = true

        case .userCancelled:
            break

        case .pending:
            break

        @unknown default:
            break
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedProducts()
    }

    private func updatePurchasedProducts() async {
        var newPurchasedIDs: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if let transaction = try? result.payloadValue {
                newPurchasedIDs.insert(transaction.productID)
            }
        }
        purchasedProductIDs = newPurchasedIDs
        isSubscribed = !purchasedProductIDs.isEmpty
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? result.payloadValue {
                    await MainActor.run {
                        self.purchasedProductIDs.insert(transaction.productID)
                        self.isSubscribed = true
                    }
                    await transaction.finish()
                }
            }
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // 無料枠チェック
    func canCreateNote(currentWeekNoteCount: Int) -> Bool {
        isSubscribed || currentWeekNoteCount < 3
    }
}
```

**App Store Connect 設定:**

| 項目 | 値 |
|------|-----|
| サブスクリプショングループ | notechain_premium |
| 月額プロダクト ID | com.yourcompany.notechain.pro_monthly |
| 年額プロダクト ID | com.yourcompany.notechain.pro_annual |
| 月額価格（US） | $3.99 |
| 年額価格（US） | $29.99 |
| 自動更新 | 有効 |
| イントロオファー | 14日間の無料トライアル |

**地域別価格:**

| 地域 | 月額 | 年額 | 通貨 |
|------|------|------|------|
| 🇺🇸 US | $3.99 | $29.99 | USD |
| 🇯🇵 JP | ¥400 | ¥2,950 | JPY |
| 🇪🇸 ES | €3.99 | €29.99 | EUR |
| 🇬🇧 UK | £3.49 | £26.99 | GBP |

**トライアル戦略:**

- 期間: 14日（データ上、3日トライアルより転換率 +70%）
- リマインダースケジュール:
  - Day 2: 「あなたの最初のプロフェッショナルノートが安全に保存されました」
  - Day 7: 「無料トライアルはあと 1 週間です」
  - Day 13: 「明日トライアルが終了します」

**受け入れ基準（Given-When-Then）:**

- Given: 初回起動ユーザー / When: オンボーディング完了後 / Then: ペイウォール画面が表示され、月額・年額・トライアル情報が正しく表示される
- Given: 無料ユーザーが週3件のノートを作成済み / When: 新しいノートを録音しようとする / Then: ペイウォールが表示され、無料枠の上限に達したことが通知される
- Given: ユーザーが年額プランを購入 / When: アプリを再起動 / Then: isSubscribed == true で全機能がアンロックされる
- Given: 有料ユーザー / When: 別デバイスで「購入情報を復元」をタップ / Then: 購読状態が正しく復元される
- Given: トライアル中のユーザー / When: Day 13 / Then: 「明日トライアルが終了します」通知が表示される

---

## 実装タイムライン（AI 駆動）

### Week 1: AI 駆動開発基盤 & スキャフォールディング

**タスク:** Claude Code 環境構築 + プロジェクト骨格

```
Claude Code で実装する内容:
1. CLAUDE.md / .claude/rules/ / .claude/skills/ / .claude/commands/ 生成
2. .mcp.json（XcodeBuildMCP 設定）
3. docs/ARCHITECTURE.md / docs/specs/template.md / docs/tasks/template.md
4. SwiftUI アプリ構造（TabView + NavigationStack + Router）
5. SwiftData スキーマ（Note @Model）
6. Shared レイヤー骨格（AppError, Router, SpeechRecognitionService プロトコル）
7. 全 Feature モジュールの骨格（View + ViewModel + README.md）
8. テスト骨格
9. Localizable.xcstrings 初期設定
```

**成果物:**

- ✅ AI駆動開発インフラ完成
- ✅ SwiftUI アプリがビルド・起動可能
- ✅ SwiftData スキーマ動作確認
- ✅ タブナビゲーション動作
- ✅ 全モジュールの骨格が存在

**工数（AI + レビュー）:** 1–2日

### Week 2: 音声認識統合

```
Claude Code で実装する内容:
1. SpeechRecognitionServiceProtocol 完全実装
2. SpeechAnalyzerService（iOS 26+）
3. LegacySpeechService（iOS 17-25 フォールバック）
4. RecordingManager（AVAudioEngine ライフサイクル管理）
5. RecordingViewModel（UI 状態管理）
6. RecordingView（録音UI + リアルタイム文字起こし表示）
7. 権限リクエストフロー
8. volatile / final result の区別表示
9. 録音完了 → Note 保存フロー
10. RecordingViewModel ユニットテスト
```

**テスト項目:**

- □ 英語で 30 秒録音 → 文字起こし精度を確認
- □ 言語設定を変更 → ロケール変更が反映されること
- □ マイク権限を拒否 → エラーが適切に表示されること
- □ 通話などで音声が中断 → 復帰動作を確認
- □ volatile results が薄紫色、final results が黒色で表示されること

**工数（AI + レビュー）:** 2–3日

### Week 3: キーワード抽出 & ノート一覧

```
Claude Code で実装する内容:
1. NLTaggerKeywordExtractor 完全実装
2. KeywordBadgeView（バッジ表示コンポーネント）
3. 録音完了 → KeywordExtractor 連携
4. NotesListView / NotesListViewModel 完全実装
5. NoteRowView（一覧行コンポーネント）
6. NoteDetailView / NoteDetailViewModel
7. 検索機能実装
8. ソート機能実装
9. スワイプ削除
10. KeywordExtractorTests / NotesListViewModelTests
```

**工数（AI + レビュー）:** 2–3日

### Week 4: 多言語対応 & ローカライズ

```
Claude Code で実装する内容:
1. Localizable.xcstrings 全キー定義（英語・日本語・スペイン語）
2. 全ハードコード文字列を LocalizedStringKey に置換
3. SettingsView / SettingsViewModel 完全実装
4. LanguagePickerView（言語選択UI）
5. 録音言語切り替えの SpeechRecognitionService 連携
6. 日本語キーワード抽出の最適化（NLTagger 日本語対応）
7. 3 言語それぞれで全画面の表示確認
```

**工数（AI + レビュー）:** 1–2日

### Week 5: サブスクリプション & StoreKit 2

```
Claude Code で実装する内容:
1. SubscriptionManager 完全実装
2. PaywallView（ペイウォール画面）
3. SubscriptionBadgeView（Pro バッジ）
4. 無料枠チェックロジック（週3件制限）
5. 機能ロック/アンロック制御
6. OnboardingView（初回起動フロー）
7. 購入復元機能
8. トライアルリマインダー通知（ローカル通知）
9. SubscriptionManagerTests
```

**工数（AI + StoreKit 設定）:** 2–3日

### Week 6: 仕上げ・テスト・App Store 申請

**QA チェックリスト:**

```
音声 & 音声認識:
□ 1, 5, 10, 30 分の録音テスト
□ 音量条件を変えて精度確認
□ 周囲雑音ありのテスト
□ 録音中に言語変更（UI のみ）
□ 権限フローの確認
□ iOS 26+ で SpeechAnalyzer 動作確認
□ iOS 17-25 で SFSpeechRecognizer フォールバック確認

UI/UX:
□ 3 言語すべてで文言がローカライズされている
□ キーワードが正しく表示される
□ 検索フィルタが機能する
□ ペイウォールに正しい価格が表示される
□ トライアル残日数の表示が正しい
□ volatile / final results の色分けが正しい

サブスクリプション:
□ 初回起動でオンボーディング → ペイウォール表示
□ トライアル後に購入可能
□ 再起動後も購入状態が保持される
□ 購入復元が機能する
□ サブスクバッジ表示確認
□ 無料枠（週3件）のカウントが正しい

パフォーマンス:
□ アプリ起動 <2 秒
□ 500 件以上のノート検索 <500ms
□ メモリリークなし（Instruments 検証）
□ キーワード抽出 <1 秒（100語テキスト）

プライバシー:
□ コア機能はネットワーク通信なし
□ 録音中のみマイク使用
□ サードパーティ分析 SDK なし（TelemetryDeck のみ・オプション）
```

**App Store 申請用素材:**

```
必須項目:
✅ アプリ名: NoteChain
✅ カテゴリ: Productivity
✅ サブタイトル: "AI-Powered Voice Notes"
✅ 説明文（約 500 文字）
✅ キーワード: voice, memo, transcription, notes, recording, AI, keyword, privacy
✅ レーティング: 4+
✅ プライバシーポリシー URL
✅ サポート用メールアドレス
✅ スクリーンショット（言語ごとに 6 枚）
✅ プレビュー動画（任意だが推奨）
```

**工数（AI + 手動テスト）:** 3–4日

---

## ユーザー体験フロー

### オンボーディングフロー

```
アプリ起動
  ↓
[権限リクエスト]
「NoteChain がマイクへのアクセスを求めています」
  ↓
[言語選択]
「録音言語を選んでください」
(English / 日本語 / Español)
  ↓
[ペイウォール]
「14日間無料トライアルを開始」
(PaywallView → SubscriptionManager.purchase())
  ↓
[サブスクリプション有効化]
  ↓
[メイン画面 - RecordingView]
「タップして最初のノートを録音」
```

### 録音セッションフロー

```
1. ユーザーが「録音」ボタンをタップ
   ↓
2. マイク有効化 + SpeechRecognitionService 開始
   ↓
3. volatile results を薄紫色テキストでリアルタイム表示
   ↓
4. final results を黒色テキストで順次確定
   ↓
5. 「停止」をタップ
   ↓
6. [ローディング] 「キーワード抽出中…」
   NLTaggerKeywordExtractor が名詞・固有名詞を解析
   ↓
7. Note を SwiftData に保存
   ↓
8. NotesListView に表示
   「Today
     • あなたの最初のノート
       #keyword1 #keyword2 #keyword3
       たった今 | 2:45」
```

### 検索 & 発見フロー

```
ユーザーが NotesListView を開く
  ↓
検索バーをタップ
  ↓
検索ワード（例: "meeting"）入力
  ↓
以下でフィルタ:
- キーワード一致
- テキスト全文一致
- 言語フィルタ
  ↓
ソート順に従ってノートを表示
```

---

## 非機能要件

### パフォーマンス目標

| 指標 | 目標値 | 測定ツール |
|------|--------|-----------|
| アプリ起動時間 | <2秒 | Xcode Instruments |
| 録音開始遅延 | <500ms | 手動テスト |
| 10秒あたり文字起こし時間 | <3秒 | ログ計測 |
| キーワード抽出時間 | <1秒 | ログ計測 |
| 検索（1,000ノート） | <500ms | Swift Benchmark |
| メモリ使用量（アイドル時） | <50MB | Xcode Memory Graph |

### 品質 & テスト

```
ユニットテスト（Swift Testing）:
□ Note の CRUD 操作
□ NLTaggerKeywordExtractor の抽出ロジック
□ 検索フィルタリング
□ SubscriptionManager の状態管理
□ RecordingViewModel の状態遷移

UI テスト:
□ 録音フローの E2E
□ ペイウォール動作
□ 言語切り替え
□ ノート一覧ソート

手動 QA:
□ すべての機能を 3 言語で確認
□ 画面サイズ（SE〜Pro Max）対応
□ iOS 17.0+ / iOS 26+ 両方で動作確認
□ アクセシビリティ（VoiceOver, Dynamic Type）
```

### プライバシー & セキュリティ

| 要件 | 実装 |
|------|------|
| オンデバイス完結 | コア機能でネットワーク通信なし |
| ノート暗号化 | iOS Data Protection（NSFileProtectionComplete） |
| マイク利用制御 | 録音時のみオーディオセッション有効 |
| トラッキングなし | サードパーティ分析 SDK 不使用（TelemetryDeck もオプション・匿名） |
| プライバシーポリシー | App 内 & Web で公開 |
| 法令遵守 | GDPR / CCPA 対応（クラウドデータなし） |

---

## マネタイズ計画 & 財務予測

### ユーザー獲得予測

保守的想定（オーガニックのみ・広告なし）:

| 期間 | インストール | トライアル開始(D14:12%) | 転換(15%) | 有料数 | MRR |
|------|------------|------------------------|----------|--------|------|
| Week 2 | 50 | 6 | 1 | 1 | $2.50 |
| Week 3 | 100 | 12 | 2 | 3 | $7.50 |
| Week 4 | 200 | 24 | 4 | 7 | $17.50 |
| Week 5 | 350 | 42 | 6 | 13 | $32.50 |
| Week 6 | 500 | 60 | 9 | 22 | $55.00 |
| Month 2 | 1,000 | 120 | 18 | 40 | $100.00 |
| Month 3 | 1,500 | 180 | 27 | 67 | $167.50 |
| Month 6 | 3,000 | 360 | 54 | 121 | $302.50 |
| Month 12 | 6,000 | 720 | 108 | 228 | $570.00 |

### 収益予測（概算）

```
1ヶ月目: $60（粗収益、Apple 手数料30%前）
3ヶ月目: $350（粗） → 約 $245（Apple 手数料後）
6ヶ月目: $1,815（粗） → 約 $1,270（手数料後）
12ヶ月目: $6,840（粗） → 約 $4,788（手数料後）

1年目総粗収益: 約 $20,000
1年目純収益（Apple 手数料後）: 約 $14,000

Apple Developer 年会費: -$99
1年目利益: 約 $13,901 ✅
```

### 感度分析

```
シナリオ A（悲観: インストール数 50% 減）:
- 12ヶ月時点有料ユーザー: 114 人
- 1年目純収益: 約 $7,050

シナリオ B（楽観: インストール数 2倍）:
- 12ヶ月時点有料ユーザー: 456 人
- 1年目純収益: 約 $29,000

シナリオ C（App Store 特集 1回獲得）:
- 12ヶ月時点有料ユーザー: 500+ 人想定
- 1年目純収益: $35,000+
```

### ユニットエコノミクス

| 指標 | 値 | 備考 |
|------|-----|------|
| CAC（顧客獲得コスト） | $0 | オーガニックのみ（広告なし） |
| LTV（1年目 LTV） | $29.99 | 年額プランベースの保守的想定 |
| LTV/CAC 比率 | ∞ | CAC がほぼ 0 のため |
| ペイバック期間 | 即時 | 初回課金で開発費を大きく上回る |
| 目標解約率 | <5% / 月 | 生産性アプリは比較的リテンションが良い |

---

## アナリティクス & 成功指標

### 追跡すべき主要指標

```
獲得:
- 日次インストール数
- ダウンロード→トライアル率（目標: 12%+）
- トライアル→有料転換率（目標: 15%+）

アクティベーション:
- Day 1 リテンション
- 初回ノート作成率
- 初週の平均ノート数/ユーザー

エンゲージメント:
- DAU / WAU / MAU
- 平均セッション時間
- 1日あたりノート数/ユーザー

リテンション:
- Week 1 リテンション
- Month 1 リテンション
- 解約率

マネタイズ:
- 有料ユーザー数
- MRR（毎月の定期収益）
- RLTV（実現 LTV）
```

### トラッキングイベント（TelemetryDeck・オプション）

```
□ app_opened
□ recording_started
□ recording_finished
□ keywords_displayed
□ search_used
□ paywall_shown
□ subscription_purchased
□ subscription_cancelled
□ language_changed
□ note_deleted
```

---

## リリース & デプロイ

### アルファ版（社内） - Week 5

- シミュレータ + 実機ビルド
- 2–3 人による手動テスト
- クリティカルバグ修正

### TestFlight（外部ベータ） - Week 5.5

- TestFlight 提出
- Discord, Reddit などで 10–20 人のテスター募集
- フィードバック収集
- バグ修正・UI 微調整

### App Store リリース - Week 6

```
申請チェックリスト:
□ 3 言語分のスクリーンショット
□ プライバシーポリシー URL 設定
□ サポートメール設定
□ カテゴリ: Productivity
□ 年齢レーティング: 4+
□ デモ動画（任意）
□ すべてのテストがパス
□ Xcode ビルドログにクリティカル警告なし
□ iOS 17 / iOS 26 両方でのテスト完了
```

**想定審査期間:** 1–3 日（Apple レビュー）

---

## 開発ツール & インフラ

### 開発マシン要件

```
- macOS 15+
- Xcode 16.0+
- 最低 16GB RAM（推奨 32GB）
- 空き容量 50GB 以上
- Apple Developer アカウント（$99/年）
```

### 開発ツール & サービス

| ツール | 用途 | コスト | 代替 |
|-------|------|--------|------|
| Claude Code | AI コーディング支援 | $20/月 | Cursor |
| XcodeBuildMCP | Claude Code ↔ Xcode 連携 | 無料 | N/A |
| Xcode | IDE | 無料 | N/A |
| GitHub | バージョン管理 | 無料 | GitLab |
| TestFlight | ベータ配布 | 無料 | N/A |
| TelemetryDeck | 分析（任意） | 無料枠あり | PostHog |
| App Store Connect | 配信 | $99/年 | N/A |

**MVP フェーズの月次コスト（概算）:**

```
Claude Code: $20
ドメイン: $10（任意）
------------------------
合計: 約 $30/月
```

---

## AI 駆動開発インフラ仕様

### CLAUDE.md 設計方針

- プロジェクトルートに配置。200行以内
- PRD と ARCHITECTURE.md を `@` インポートで参照
- 絶対遵守ルール5つ以内（詳細はrules/に委譲）
- XcodeBuildMCP コマンドリファレンスを含む
- 開発ワークフロー: Plan → Spec → Implement → Test → Review

### .claude/rules/ 設計

| ファイル | paths 指定 | ロード条件 |
|---------|-----------|-----------|
| general.md | なし | 常時 |
| security.md | なし | 常時 |
| swift-style.md | `**/*.swift` | Swift ファイル編集時 |
| swiftui.md | `**/*View.swift` | View ファイル編集時 |
| swiftdata.md | `**/Models/**/*.swift` | Model ファイル編集時 |
| testing.md | `**/*Tests.swift` | テストファイル編集時 |
| subscription.md | `**/Subscription/**/*.swift` | Subscription モジュール編集時 |

### Agent Skills

| スキル | 用途 |
|-------|------|
| implement-feature | PRD→Spec→タスク→実装の一貫ワークフロー |
| code-review | Swift 6 / SwiftUI / セキュリティ観点のレビュー |
| test-generator | ViewModel に対する Swift Testing テスト自動生成 |

### スラッシュコマンド

| コマンド | 用途 |
|---------|------|
| /build | XcodeBuildMCP 経由でビルド |
| /test | XcodeBuildMCP 経由でテスト実行 |
| /generate-spec | PRDから機能仕様書を生成 |
| /generate-tasks | 仕様書からタスク分割を生成 |
| /implement-feature | 指定機能の実装を開始 |

---

## リスクと対策

| リスク | 確率 | 影響 | 対策 |
|--------|------|------|------|
| SpeechAnalyzer が iOS 26 未満で使えない | 確実 | 中 | SFSpeechRecognizer フォールバックを実装。SpeechRecognitionServiceProtocol で抽象化済み |
| 音声認識精度が低い | 中 | 高 | 手動編集を前提 UI にする / volatile→final の段階表示で体験向上 |
| NLTagger のキーワード精度が不十分 | 中 | 中 | ストップワード辞書の拡充 / v1.1 で Core ML モデルに移行 |
| App Store での発見性不足 | 高 | 中 | キーワード最適化 / Indie アプリ紹介サイトに投稿 |
| ユーザーが Otter.ai を好む | 中 | 中 | プライバシーと価格優位性を前面に訴求 |
| トライアル後の解約率が高い | 高 | 中 | Day 2/7/13 のエンゲージメント施策 |
| Swift 6 Strict Concurrency でビルドエラー多発 | 中 | 中 | .claude/rules/swift-style.md で Concurrency ルールを厳密に定義。AIがパターンを守る |
| SwiftData と @Observable の相互作用でデッドロック | 低 | 高 | ViewModel は @MainActor 固定。バックグラウンドI/O は ModelActor で分離 |
| iOS API の仕様変更 | 低 | 中 | WWDC 追従・新 OS リリースの監視 |

---

## 成功判定基準（Go / No-Go）

### Go 判断条件

```
✅ App Store 審査通過
✅ TestFlight ベータユーザー 50 人以上
✅ Day 7 で DAU 100 人以上
✅ Day 1 リテンション 30%以上
✅ トライアル→有料転換 10%以上
✅ 実機テストで致命的バグなし
✅ SpeechAnalyzer (iOS 26) / SFSpeechRecognizer (iOS 17) 両方で動作確認済み
✅ 3言語すべてでローカライズ完了
✅ キーワード抽出が英語・日本語で実用的に動作
```

### Kill / ピボット条件

```
❌ App Store で繰り返し却下（修正後も改善なし）
❌ TestFlight インストールが 1 週間で 20 未満
❌ Day 1 リテンション 15% 未満
❌ トライアル→有料転換 5% 未満
❌ 音声認識精度 75% 未満
```

---

## 付録: Claude Code プロンプトライブラリ

### テンプレート 1: 機能実装依頼

```
## [機能名] の実装

**コンテキスト:**
NoteChain はオンデバイス文字起こしを備えたボイスメモアプリ。
スタック: SwiftUI, SwiftData, SpeechAnalyzer/SFSpeechRecognizer, NaturalLanguage, StoreKit 2
アーキテクチャ: MVVM + @Observable + Vertical Slice
Concurrency: Swift 6 Strict Concurrency（@MainActor ViewModel, ModelActor for I/O）

**機能概要:**
[機能の説明]

**要件:**
1. [要件 1]
2. [要件 2]
3. [要件 3]

**受け入れ基準（Given-When-Then）:**
- Given: [前提条件] / When: [操作] / Then: [期待結果]
- Given: [前提条件] / When: [操作] / Then: [期待結果]

**作成 / 変更ファイル:**
- [ファイルパス 1]
- [ファイルパス 2]

NEVER: @ObservedObject / @Published / ObservableObject を使わない。
ALWAYS: @Observable + @MainActor を使う。
ALWAYS: エラーハンドリング・メモリ管理・UI 応答性のベストプラクティスを用いる。
```

### テンプレート 2: バグ修正依頼

```
## [バグ内容] の修正

**問題:**
[バグの説明]

**期待される動作:**
[あるべき挙動]

**実際の動作:**
[現状の挙動]

**再現手順:**
1. [ステップ 1]
2. [ステップ 2]

**該当コード:**
swift
// 問題のあるコード


修正方針（仮説）: [原因の仮説]
```

---

## 用語集

| 用語 | 定義 |
|------|------|
| **SpeechAnalyzer** | WWDC25 発表。iOS 26+ の次世代音声認識API。AsyncSequence ネイティブ |
| **SFSpeechRecognizer** | iOS 10+ の音声認識API。iOS 26 以降は SpeechAnalyzer が推奨 |
| **NLTagger** | NaturalLanguage フレームワークの品詞タグ付けAPI。キーワード抽出に使用 |
| **@Observable** | Swift 5.9+ のObservation マクロ。ObservableObject の後継 |
| **SwiftData** | Apple の宣言的データ永続化フレームワーク（iOS 17+） |
| **Core ML** | Apple のオンデバイス機械学習フレームワーク（v1.1+ で使用予定） |
| **StoreKit 2** | Apple のネイティブ内課金・サブスクフレームワーク |
| **Vertical Slice** | 機能単位でコードを縦割り配置するアーキテクチャパターン |
| **volatile results** | SpeechAnalyzer の途中経過テキスト（高速だが変更される可能性あり） |
| **final results** | SpeechAnalyzer の確定テキスト（変更されない） |
| **LTV** | Lifetime Value：一人の顧客から生涯で得られる収益 |
| **CAC** | Customer Acquisition Cost：顧客一人を獲得するコスト |
| **Churn Rate** | サブスク解約率（月次） |
| **GWT** | Given-When-Then：受け入れ基準の記述形式 |

---

## 最終チェックリスト

**プロダクト定義:**
□ ターゲットユーザー定義
□ 市場機会検証
□ 競合分析
□ 価格戦略策定

**技術設計:**
□ 技術スタック選定（SpeechAnalyzer + NLTagger + @Observable）
□ アーキテクチャ設計（Vertical Slice + MVVM）
□ データスキーマ設計（SwiftData @Model）
□ 音声認識の二層アーキテクチャ（SpeechAnalyzer / SFSpeechRecognizer）
□ Concurrency 方針（Swift 6 Strict）

**AI 駆動開発:**
□ CLAUDE.md 設計
□ .claude/rules/ 設計（7ファイル）
□ Agent Skills 設計（3スキル）
□ スラッシュコマンド設計（5コマンド）
□ XcodeBuildMCP 設定

**開発:**
□ プロジェクトスキャフォールド（Vertical Slice）
□ フェーズ 1 機能の優先度
□ 各機能の受け入れ基準（GWT形式）
□ テスト戦略定義（Swift Testing）

**マネタイズ:**
□ 価格ティア定義
□ StoreKit 2 設定
□ トライアル戦略
□ 収益予測モデル

**ローンチ:**
□ App Store Connect 設定
□ TestFlight ベータ計画
□ マーケティング素案
□ 成功指標の明確化

**ポストローンチ:**
□ アナリティクスダッシュボード
□ ユーザーフィードバック導線
□ v1.1 以降のロードマップ（Core ML キーワード抽出、iCloud 同期）
□ サポート体制

---

**ドキュメントオーナー:** [kiki-her]
**最終更新:** 2026-04-01
**次回レビュー:** 2026-05-01（ローンチ前）
