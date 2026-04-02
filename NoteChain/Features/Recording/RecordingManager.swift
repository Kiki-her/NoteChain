// RecordingManager.swift
// NoteChain/Features/Recording/RecordingManager.swift
//
// 責務: AVAudioSession のライフサイクル管理（カテゴリ設定・割り込み・ルート変更）
//       マイク権限・音声認識権限のチェックとリクエスト
//
// ARCHITECTURE.md §2.1 準拠
// Swift 6 Strict Concurrency: @MainActor @Observable

import AVFoundation
import Speech
import Foundation

// MARK: - Permission Status

enum PermissionStatus: Equatable {
    case authorized
    case denied
    case notDetermined
    case restricted
}

enum RecordingPermissionResult: Equatable {
    case allGranted
    case microphoneDenied
    case speechRecognitionDenied
    case bothDenied
}

// MARK: - RecordingManager

@MainActor
@Observable
final class RecordingManager: NSObject {

    // MARK: - Public Properties

    /// AVAudioSession がアクティブかどうか
    var isAudioSessionActive: Bool = false

    /// 割り込み終了後に再開可能かどうか（UI で「再開」ボタン表示の判断に使用）
    var canResumeAfterInterruption: Bool = false

    /// 現在の入力デバイス名（Bluetooth マイクなど）
    var currentInputPortName: String? = nil

    // MARK: - Private Properties

    private var interruptionObserver: NSObjectProtocol?
    private var routeChangeObserver: NSObjectProtocol?

    // MARK: - Lifecycle

    override init() {
        super.init()
        setupNotificationObservers()
    }

    deinit {
        // NSObjectProtocol observer の解除
        if let obs = interruptionObserver {
            NotificationCenter.default.removeObserver(obs)
        }
        if let obs = routeChangeObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    // MARK: - Public: Audio Session

    /// AVAudioSession を録音用に設定してアクティベートする
    /// - Throws: AVAudioSession 設定・起動エラー
    func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .record,
            mode: .measurement,
            options: [.duckOthers, .allowBluetooth]
        )
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        isAudioSessionActive = true
        updateCurrentInputPort()
    }

    /// AVAudioSession を非アクティブにする（録音停止後に呼ぶ）
    func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
        } catch {
            // セッション無効化失敗はクリティカルではないためログのみ
            #if DEBUG
            print("[RecordingManager] deactivateAudioSession error: \(error)")
            #endif
        }
        isAudioSessionActive = false
    }

    // MARK: - Public: Permission

    /// マイクと音声認識の両権限をチェックし、未設定なら順にリクエストする
    /// - Returns: 両権限の総合結果
    func requestPermissionsIfNeeded() async -> RecordingPermissionResult {
        let micStatus = await requestMicrophonePermission()
        let speechStatus = await requestSpeechRecognitionPermission()

        switch (micStatus, speechStatus) {
        case (.authorized, .authorized):
            return .allGranted
        case (.denied, .authorized), (.denied, .notDetermined), (.denied, .restricted):
            return .microphoneDenied
        case (.authorized, .denied), (.authorized, .restricted):
            return .speechRecognitionDenied
        default:
            return .bothDenied
        }
    }

    /// 現在のマイク権限ステータスを返す（リクエストなし）
    func microphonePermissionStatus() -> PermissionStatus {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:   return .authorized
        case .denied:    return .denied
        case .undetermined: return .notDetermined
        @unknown default: return .restricted
        }
    }

    /// 現在の音声認識権限ステータスを返す（リクエストなし）
    func speechRecognitionPermissionStatus() -> PermissionStatus {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:    return .authorized
        case .denied:        return .denied
        case .notDetermined: return .notDetermined
        case .restricted:    return .restricted
        @unknown default:    return .restricted
        }
    }

    // MARK: - Private: Permission Requests

    private func requestMicrophonePermission() async -> PermissionStatus {
        let current = microphonePermissionStatus()
        guard current == .notDetermined else { return current }

        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted ? .authorized : .denied)
            }
        }
    }

    private func requestSpeechRecognitionPermission() async -> PermissionStatus {
        let current = speechRecognitionPermissionStatus()
        guard current == .notDetermined else { return current }

        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                switch status {
                case .authorized:    continuation.resume(returning: .authorized)
                case .denied:        continuation.resume(returning: .denied)
                case .restricted:    continuation.resume(returning: .restricted)
                case .notDetermined: continuation.resume(returning: .notDetermined)
                @unknown default:    continuation.resume(returning: .restricted)
                }
            }
        }
    }

    // MARK: - Private: Notification Observers

    private func setupNotificationObservers() {
        // 割り込み通知（電話着信など）
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                await self?.handleAudioSessionInterruption(notification)
            }
        }

        // ルート変更通知（Bluetooth マイク接続・切断など）
        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                self?.handleRouteChange(notification)
            }
        }
    }

    // MARK: - Private: Interruption Handling

    func handleAudioSessionInterruption(_ notification: Notification) async {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            // 電話着信など → 録音一時停止
            isAudioSessionActive = false
            canResumeAfterInterruption = false
            #if DEBUG
            print("[RecordingManager] Audio session interrupted (began)")
            #endif

        case .ended:
            // 割り込み終了 → shouldResume フラグを確認
            let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            canResumeAfterInterruption = options.contains(.shouldResume)
            #if DEBUG
            print("[RecordingManager] Audio session interruption ended. canResume: \(canResumeAfterInterruption)")
            #endif

        @unknown default:
            break
        }
    }

    // MARK: - Private: Route Change Handling

    private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
        else { return }

        switch reason {
        case .newDeviceAvailable, .oldDeviceUnavailable, .override, .wakeFromSleep:
            // 入力デバイスが変わった → 現在のポート名を更新
            updateCurrentInputPort()
            #if DEBUG
            print("[RecordingManager] Route changed: \(reason). New input: \(currentInputPortName ?? "none")")
            #endif
        default:
            break
        }
    }

    private func updateCurrentInputPort() {
        let inputs = AVAudioSession.sharedInstance().currentRoute.inputs
        currentInputPortName = inputs.first?.portName
    }
}
