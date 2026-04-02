// NoteChain/Features/Recording/RecordingManager.swift
// AVAudioSession のライフサイクル管理（割り込み対応）

import AVFoundation
import Foundation

/// AVAudioSession の設定・割り込み（着信など）への対応を担う。
/// RecordingViewModel から利用される。
@Observable
final class RecordingManager {

    /// オーディオセッションがアクティブかどうか
    var isAudioSessionActive: Bool = false

    /// 割り込みによる一時停止フラグ（呼び出し元が復帰処理を行う）
    var isInterrupted: Bool = false

    // MARK: - セッション設定

    /// 録音用にオーディオセッションを設定してアクティベートする。
    func activateRecordingSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        isAudioSessionActive = true

        // 重複登録を防ぐため先に解除してから登録
        NotificationCenter.default.removeObserver(
            self,
            name: AVAudioSession.interruptionNotification,
            object: session
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: session
        )
    }

    /// オーディオセッションを非アクティブにする。
    func deactivateRecordingSession() {
        NotificationCenter.default.removeObserver(
            self,
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
        isAudioSessionActive = false
    }

    // MARK: - 割り込みハンドリング

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            isInterrupted = true
        case .ended:
            isInterrupted = false
            // 割り込み終了後の復帰は呼び出し元（RecordingViewModel）が判断
        @unknown default:
            break
        }
    }
}
