// NoteChain/App/ContentView.swift
// TabView ルートビュー + Router 統合

import SwiftData
import SwiftUI

/// アプリのルートビュー。TabView で 3 タブを管理し、
/// NavigationStack + Router でタブ内遷移を提供する。
struct ContentView: View {

    @Environment(Router.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTab: AppTab = .record

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: 録音タブ
            recordingTab

            // MARK: ノート一覧タブ
            notesTab

            // MARK: 設定タブ
            settingsTab
        }
        .sheet(
            isPresented: Bindable(appState).isShowingPaywall
        ) {
            PaywallView()
                .environment(subscriptionManager)
        }
        .alert(
            "error_title",
            isPresented: Binding(
                get: { appState.globalError != nil },
                set: { if !$0 { appState.clearError() } }
            )
        ) {
            Button("ok_button", role: .cancel) { appState.clearError() }
        } message: {
            if let error = appState.globalError {
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - タブビュー定義

    @ViewBuilder
    private var recordingTab: some View {
        RecordingView(modelContext: modelContext)
            .tabItem {
                Label(AppTab.record.labelKey, systemImage: AppTab.record.systemImage)
            }
            .tag(AppTab.record)
    }

    @ViewBuilder
    private var notesTab: some View {
        NavigationStack(path: Bindable(router).notesPath) {
            NotesListView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .noteDetail(let id):
                        NoteDetailView(noteID: id)
                    case .keywordFilter(let keyword):
                        NotesListView(keywordFilter: keyword)
                    default:
                        EmptyView()
                    }
                }
        }
        .tabItem {
            Label(AppTab.notes.labelKey, systemImage: AppTab.notes.systemImage)
        }
        .tag(AppTab.notes)
    }

    @ViewBuilder
    private var settingsTab: some View {
        NavigationStack(path: Bindable(router).settingsPath) {
            SettingsView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .languagePicker:
                        LanguagePickerView()
                    case .subscriptionManagement:
                        PaywallView()
                            .environment(subscriptionManager)
                    default:
                        EmptyView()
                    }
                }
        }
        .tabItem {
            Label(AppTab.settings.labelKey, systemImage: AppTab.settings.systemImage)
        }
        .tag(AppTab.settings)
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Note.self, configurations: config)
    let router = Router()
    let appState = AppState()
    let subscriptionManager = SubscriptionManager.preview

    ContentView()
        .modelContainer(container)
        .environment(router)
        .environment(appState)
        .environment(subscriptionManager)
        .environment(SettingsViewModel())
}
