---
description: "セキュリティ・プライバシー禁則事項（常時ロード）"
---

# NoteChain — セキュリティルール

## ネットワーク通信

CRITICAL: MVP フェーズでは URLSession / Alamofire 等のネットワーク通信を禁止する。
          例外は StoreKit 2（自動）と TelemetryDeck（オプション・匿名のみ）のみ。

NEVER:    音声データ・文字起こしテキストをネットワーク経由で送信してはならない。
          すべての音声認識はオンデバイスで完結させる。

## 音声認識プライバシー

CRITICAL: `SFSpeechAudioBufferRecognitionRequest` では必ず
          `request.requiresOnDeviceRecognition = true` を設定すること。
          クラウド送信を防ぐための最重要設定。

ALWAYS:   マイクの `AVAudioSession` は録音開始時のみ `.record` カテゴリでアクティベートする。
          録音停止後は即座に `setActive(false, options: .notifyOthersOnDeactivation)` を呼ぶ。

## データ保護

ALWAYS:   SwiftData ストアと音声ファイルは iOS Data Protection
          (`NSFileProtectionComplete`) を適用すること。
          ModelConfiguration に fileProtection: .complete を設定する。

NEVER:    API キー・秘密情報を UserDefaults や @AppStorage に保存してはならない。
          機密情報は Keychain のみ使用可。

## ロギング

NEVER:    本番ビルドで `print()` や `Logger` に文字起こしテキストや個人情報を出力してはならない。
          デバッグ出力は `#if DEBUG` で必ず囲むこと。

## サードパーティ SDK

NEVER:    MVP フェーズでは外部 SDK を CocoaPods / SPM で追加してはならない。
          追加が必要な場合はレビュー承認後のみ許可。

## Info.plist

ALWAYS:   `NSMicrophoneUsageDescription` と `NSSpeechRecognitionUsageDescription` には
          具体的な利用目的を英語で記載すること（App Store 審査要件）。
