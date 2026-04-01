// NoteChain/Features/Settings/SettingsView.swift
// 設定ルート画面

import SwiftUI

/// ユーザー設定画面。録音言語・UI言語・サブスクリプション・アプリ情報を表示する。
struct SettingsView: View {

    @Environment(SettingsViewModel.self) private var viewModel
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(Router.self) private var router

    var body: some View {
        NavigationStack(path: Bindable(router).settingsPath) {
            Form {
                // 録音言語セクション
                Section {
                    NavigationLink {
                        LanguagePickerView(
                            selectedLanguage: Bindable(viewModel).recordingLanguage
                        )
                    } label: {
                        HStack {
                            Label("recording_language_label", systemImage: "mic.fill")
                            Spacer()
                            Text(currentLanguageDisplay)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("recording_language_section_header")
                }

                // UI 言語セクション
                Section {
                    Picker("ui_language_label", selection: Bindable(viewModel).uiLanguage) {
                        ForEach(SettingsViewModel.supportedUILanguages, id: \.code) { lang in
                            Text(lang.name).tag(lang.code)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("ui_language_section_header")
                }

                // サブスクリプションセクション
                Section {
                    HStack {
                        Label("subscription_status_label", systemImage: "crown.fill")
                        Spacer()
                        SubscriptionBadgeView()
                    }

                    if !subscriptionManager.isSubscribed {
                        Button("upgrade_to_pro_button") {
                            router.push(.subscriptionManagement, in: .settings)
                        }
                        .foregroundStyle(.accentColor)
                    }
                } header: {
                    Text("subscription_section_header")
                }

                // アプリ情報セクション
                Section {
                    Link(destination: URL(string: "https://notechain.app/privacy")!) {
                        Label("privacy_policy_label", systemImage: "hand.raised.fill")
                    }
                    Link(destination: URL(string: "https://notechain.app/terms")!) {
                        Label("terms_of_service_label", systemImage: "doc.text.fill")
                    }
                    LabeledContent(
                        String(localized: "version_label"),
                        value: Bundle.main.appVersionString
                    )
                } header: {
                    Text("about_section_header")
                }
            }
            .navigationTitle("settings_title")
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .languagePicker:
                    LanguagePickerView(selectedLanguage: Bindable(viewModel).recordingLanguage)
                case .subscriptionManagement:
                    PaywallView()
                default:
                    EmptyView()
                }
            }
        }
    }

    // MARK: - ヘルパー

    private var currentLanguageDisplay: String {
        SettingsViewModel.supportedRecordingLanguages
            .first { $0.code == viewModel.recordingLanguage }
            .map { "\($0.flag) \($0.name)" } ?? viewModel.recordingLanguage
    }
}

#Preview {
    SettingsView()
        .environment(SettingsViewModel())
        .environment(SubscriptionManager())
        .environment(Router())
}
