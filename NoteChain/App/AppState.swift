// NoteChain/App/AppState.swift
// アプリグローバル状態（オンボーディング完了・ペイウォール表示）

import Foundation
import SwiftUI

/// アプリ全体で共有するグローバル状態。
/// @Environment(AppState.self) で各 View から参照する。
@MainActor
@Observable
final class AppState {

    // MARK: - 公開プロパティ

    /// オンボーディング完了フラグ（@AppStorage で永続化）
    @AppStorage("hasCompletedOnboarding")
    var hasCompletedOnboarding: Bool = false

    /// ペイウォールシート表示フラグ
    var isShowingPaywall: Bool = false

    /// グローバルエラー（ルートレベルのアラート表示用）
    var globalError: AppError? = nil

    // MARK: - 公開メソッド

    /// オンボーディングを完了としてマークする。
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    /// ペイウォールを表示する。
    func showPaywall() {
        isShowingPaywall = true
    }

    /// ペイウォールを閉じる。
    func dismissPaywall() {
        isShowingPaywall = false
    }

    /// グローバルエラーをセットする。
    func setError(_ error: AppError) {
        globalError = error
    }

    /// グローバルエラーをクリアする。
    func clearError() {
        globalError = nil
    }
}
