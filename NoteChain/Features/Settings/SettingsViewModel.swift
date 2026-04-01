// NoteChain/Features/Settings/SettingsViewModel.swift
// ユーザー設定の状態管理 ViewModel

import Foundation
import SwiftUI

/// ユーザー設定を @AppStorage で永続化する ViewModel。
/// @Environment(SettingsViewModel.self) で Recording など他モジュールから参照する。
@MainActor
@Observable
final class SettingsViewModel {

    // MARK: - @AppStorage 永続化プロパティ
    // @Observable と @AppStorage を組み合わせる場合は _変数名 でラップを参照する

    @AppStorage("recordingLanguage")
    var recordingLanguage: String = "en-US"

    @AppStorage("uiLanguage")
    var uiLanguage: String = "system"

    @AppStorage("hasCompletedOnboarding")
    var hasCompletedOnboarding: Bool = false

    @AppStorage("weeklyNoteCount")
    var weeklyNoteCount: Int = 0

    @AppStorage("weeklyNoteCountResetTimestamp")
    private var weeklyResetTimestamp: Double = Date().timeIntervalSince1970

    // MARK: - 計算プロパティ

    /// 録音言語設定から生成した Locale
    var speechLocale: Locale {
        if recordingLanguage == "auto" {
            return Locale.current
        }
        return Locale(identifier: recordingLanguage)
    }

    /// 自動検出モードかどうか
    var isAutoDetectLanguage: Bool {
        recordingLanguage == "auto"
    }

    // MARK: - 静的定義

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

    // MARK: - 公開メソッド

    /// 毎週月曜日に weeklyNoteCount をリセットする。
    /// アプリ起動時や録音開始前に呼ぶ。
    func resetWeeklyCountIfNeeded() {
        let resetDate = Date(timeIntervalSince1970: weeklyResetTimestamp)
        let calendar = Calendar.current

        // 前回リセットから7日以上経過しているか確認
        guard let daysElapsed = calendar.dateComponents(
            [.day],
            from: resetDate,
            to: Date()
        ).day, daysElapsed >= 7 else { return }

        weeklyNoteCount = 0
        weeklyResetTimestamp = Date().timeIntervalSince1970
    }

    /// 週のノートカウントを1増やす。
    func incrementWeeklyNoteCount() {
        resetWeeklyCountIfNeeded()
        weeklyNoteCount += 1
    }
}
