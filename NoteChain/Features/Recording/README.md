# Recording モジュール

## 目的

音声録音とリアルタイム文字起こし機能を担当する Feature モジュール。

## 責務

- AVAudioSession のライフサイクル管理（開始・停止・割り込み対応）
- `SpeechRecognitionServiceProtocol` 経由での音声→テキスト変換
- volatile（暫定）/ final（確定）結果の UI への反映
- 録音完了後の Note 保存と KeywordExtractor への連携
- マイク・音声認識権限のリクエスト

## ファイル一覧

| ファイル | 役割 |
|---------|------|
| `RecordingView.swift` | メイン録音 UI（マイクボタン・テキスト表示・タイマー） |
| `RecordingViewModel.swift` | 録音状態管理 ViewModel（@MainActor @Observable） |
| `RecordingManager.swift` | AVAudioSession ライフサイクル管理 |

## 依存関係

- `Shared/Services/SpeechRecognitionService` — 音声認識（DI）
- `Shared/Models/Note` — SwiftData 保存先
- `Shared/Models/AppError` — エラー処理
- `Shared/Navigation/Router` — 保存後のノート詳細遷移
- `Shared/Components/PermissionDeniedView` — 権限拒否表示
- `Shared/Components/LoadingOverlay` — 保存中表示
- `Features/Keywords/KeywordExtractor` — 録音完了後に呼び出す
- `Features/Subscription/SubscriptionManager` — 無料枠チェック（@Environment）
- `Features/Settings/SettingsViewModel` — 録音言語取得（@Environment）

## 重要な設計決定

- `SpeechRecognitionServiceFactory.create()` で iOS バージョンに応じた実装を自動選択
- volatile テキスト = 薄紫色（`.purple.opacity(0.5)`）
- final テキスト = プライマリカラー（黒）
- 録音停止時は `stopAndSave()` で原子的に「停止→抽出→保存」を実行
