// NoteChain/Features/Onboarding/OnboardingViewModel.swift
// オンボーディング状態管理 ViewModel

import AVFoundation
import Foundation
import Speech
import SwiftUI

/// オンボーディングのページ進行と権限リクエストを管理する ViewModel。
@MainActor
@Observable
final class OnboardingViewModel {

    // MARK: - 公開プロパティ

    /// 現在表示中のページ（0-2）
    var currentPage: Int = 0

    /// マイク権限が付与済みかどうか
    var microphoneGranted: Bool = false

    /// 音声認識権限が付与済みかどうか
    var speechGranted: Bool = false

    /// 権限リクエスト中フラグ
    var isRequestingPermission: Bool = false

    // MARK: - 定数

    static let totalPages: Int = 3

    // MARK: - 公開メソッド

    /// 次のページに進む。最終ページでは .onboardingCompleted 通知を投げる。
    func advance() {
        if currentPage < Self.totalPages - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            // 最終ページ → オンボーディング完了を AppState に通知
            NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
        }
    }

    /// 前のページに戻る。
    func goBack() {
        guard currentPage > 0 else { return }
        withAnimation {
            currentPage -= 1
        }
    }

    /// マイク・音声認識の権限をリクエストする。
    func requestPermissions() async {
        isRequestingPermission = true
        defer { isRequestingPermission = false }

        // マイク権限
        switch AVAudioApplication.shared.recordPermission {
        case .undetermined:
            let granted = await AVAudioApplication.requestRecordPermission()
            microphoneGranted = granted
        case .granted:
            microphoneGranted = true
        case .denied:
            microphoneGranted = false
        @unknown default:
            break
        }

        // 音声認識権限
        switch SFSpeechRecognizer.authorizationStatus() {
        case .notDetermined:
            let status = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
            }
            speechGranted = (status == .authorized)
        case .authorized:
            speechGranted = true
        case .denied, .restricted:
            speechGranted = false
        @unknown default:
            break
        }
    }

    /// 権限が全て付与されているかどうか
    var allPermissionsGranted: Bool {
        microphoneGranted && speechGranted
    }
}
