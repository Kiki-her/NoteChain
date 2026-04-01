// NoteChain/Shared/Navigation/Router.swift
// NavigationStack + Route enum ベースのルーター

import Foundation
import SwiftUI

// MARK: - Route

/// アプリ内の画面遷移先を表す型安全な enum。
/// NavigationStack の path として使用する。
enum Route: Hashable {
    // NotesList タブ内の遷移
    case noteDetail(UUID)
    case keywordFilter(String)

    // Settings タブ内の遷移
    case languagePicker
    case subscriptionManagement
}

// MARK: - AppTab

/// タブバーのタブ定義。
enum AppTab: String, CaseIterable, Identifiable {
    case record   = "record"
    case notes    = "notes"
    case settings = "settings"

    var id: String { rawValue }

    var labelKey: LocalizedStringKey {
        switch self {
        case .record:   "tab_record"
        case .notes:    "tab_notes"
        case .settings: "tab_settings"
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

// MARK: - Router

/// NavigationStack の path を管理する @Observable ルーター。
/// @Environment(Router.self) で各 View から参照する。
@MainActor
@Observable
final class Router {

    /// NotesList タブのナビゲーションパス
    var notesPath: NavigationPath = NavigationPath()

    /// Settings タブのナビゲーションパス
    var settingsPath: NavigationPath = NavigationPath()

    // MARK: - ナビゲーション操作

    /// 指定タブのスタックに画面をプッシュする
    func push(_ route: Route, in tab: AppTab = .notes) {
        switch tab {
        case .notes:
            notesPath.append(route)
        case .settings:
            settingsPath.append(route)
        case .record:
            break // 録音タブはナビゲーションスタックを持たない
        }
    }

    /// 指定タブのスタックから1画面ポップする
    func pop(from tab: AppTab = .notes) {
        switch tab {
        case .notes:
            if !notesPath.isEmpty { notesPath.removeLast() }
        case .settings:
            if !settingsPath.isEmpty { settingsPath.removeLast() }
        case .record:
            break
        }
    }

    /// 指定タブのスタックをルートに戻す
    func popToRoot(in tab: AppTab = .notes) {
        switch tab {
        case .notes:
            notesPath = NavigationPath()
        case .settings:
            settingsPath = NavigationPath()
        case .record:
            break
        }
    }
}
