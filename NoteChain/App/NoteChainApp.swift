// NoteChain/App/NoteChainApp.swift
// @main エントリポイント — ModelContainer, 環境オブジェクト注入

import SwiftData
import SwiftUI

@main
struct NoteChainApp: App {

    // MARK: - シングルトン状態オブジェクト

    @State private var router = Router()
    @State private var appState = AppState()
    @State private var settingsViewModel = SettingsViewModel()
    @State private var subscriptionManager = SubscriptionManager()

    // MARK: - SwiftData コンテナ

    private let modelContainer: ModelContainer = {
        let schema = Schema([Note.self])

        // UIテスト時はインメモリコンテナを使用（データが永続化されない）
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--ui-testing")
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isUITesting
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer 初期化失敗: \(error)")
        }
    }()

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView()
                        .environment(OnboardingViewModel())
                        .onReceive(
                            NotificationCenter.default.publisher(
                                for: .onboardingCompleted
                            )
                        ) { _ in
                            appState.completeOnboarding()
                        }
                }
            }
            .modelContainer(modelContainer)
            .environment(router)
            .environment(appState)
            .environment(settingsViewModel)
            .environment(subscriptionManager)
            .task {
                // UIテスト時はオンボーディングをスキップ
                if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
                    appState.completeOnboarding()
                }

                await subscriptionManager.initialize()
                settingsViewModel.resetWeeklyCountIfNeeded()
            }
        }
    }
}

// MARK: - Notification 名

extension Notification.Name {
    /// OnboardingViewModel から AppState へ完了を通知するキー
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}
