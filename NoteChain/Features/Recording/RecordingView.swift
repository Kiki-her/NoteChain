// NoteChain/Features/Recording/RecordingView.swift
// 録音メイン画面 — マイクボタン・リアルタイム文字起こし表示・タイマー

import SwiftData
import SwiftUI

/// 録音画面のルートビュー。
/// タップで録音開始/停止、volatile/final テキストをリアルタイム表示する。
struct RecordingView: View {

    @State private var viewModel: RecordingViewModel
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(SettingsViewModel.self) private var settingsViewModel
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext

    init() {
        // modelContext は .task 内で設定するため、ここでは仮の初期化
        // 実際の DI は onAppear / .task で行う
        _viewModel = State(wrappedValue: RecordingViewModel(modelContext: ModelContext(try! ModelContainer(for: Note.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    // 文字起こし表示エリア
                    transcriptArea

                    Spacer()

                    // 録音時間
                    if viewModel.isRecording {
                        RecordingTimerView(duration: viewModel.recordingDuration)
                    }

                    // マイクボタン
                    RecordButton(
                        isRecording: viewModel.isRecording,
                        isDisabled: viewModel.microphonePermissionDenied || viewModel.speechPermissionDenied
                    ) {
                        Task {
                            await viewModel.toggleRecording(
                                locale: settingsViewModel.speechLocale,
                                canCreateNote: subscriptionManager.canCreateNote(
                                    currentWeekNoteCount: settingsViewModel.weeklyNoteCount
                                )
                            )
                        }
                    }
                    .padding(.bottom, 48)
                }
                .padding(.horizontal)

                // 権限拒否バナー
                if viewModel.microphonePermissionDenied {
                    VStack {
                        PermissionDeniedView(type: .microphone)
                        Spacer()
                    }
                    .padding(.top)
                }

                // 保存中オーバーレイ
                if viewModel.isSaving {
                    LoadingOverlay(message: "saving_note")
                }
            }
            .navigationTitle("tab_record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.isRecording {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("stop_button") {
                            Task { await viewModel.toggleRecording(
                                locale: settingsViewModel.speechLocale,
                                canCreateNote: true
                            )}
                        }
                        .tint(.red)
                    }
                }
            }
        }
        .task {
            await viewModel.checkPermissions()
        }
        .onChange(of: viewModel.didSaveNote) { _, saved in
            if saved, let noteID = viewModel.savedNoteID {
                router.push(.noteDetail(noteID), in: .notes)
                viewModel.didSaveNote = false
            }
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView()
        }
        .alert(
            "error_title",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
            )
        ) {
            Button("ok_button", role: .cancel) { viewModel.clearError() }
        } message: {
            if let msg = viewModel.errorMessage {
                Text(msg)
            }
        }
    }

    // MARK: - Subviews

    private var transcriptArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                // 確定済みテキスト（黒）
                if !viewModel.finalTranscript.isEmpty {
                    Text(viewModel.finalTranscript)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(.easeInOut, value: viewModel.finalTranscript)
                }

                // 暫定テキスト（薄紫）
                if !viewModel.volatileTranscript.isEmpty {
                    Text(viewModel.volatileTranscript)
                        .font(.body)
                        .foregroundStyle(.purple.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(.easeInOut, value: viewModel.volatileTranscript)
                }

                // プレースホルダー
                if viewModel.finalTranscript.isEmpty && viewModel.volatileTranscript.isEmpty {
                    Text(viewModel.isRecording ? "recording_placeholder" : "tap_to_record")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding()
        }
        .frame(maxHeight: 320)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(viewModel.isRecording ? Color.red.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeInOut, value: viewModel.isRecording)
    }
}

// MARK: - RecordButton

private struct RecordButton: View {
    let isRecording: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red : Color.accentColor)
                    .frame(width: 80, height: 80)
                    .shadow(color: isRecording ? .red.opacity(0.4) : .accentColor.opacity(0.3),
                            radius: isRecording ? 16 : 8)
                    .scaleEffect(isRecording ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                               value: isRecording)

                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1.0)
        .accessibilityLabel(isRecording ? "stop_recording" : "start_recording")
    }
}

// MARK: - RecordingTimerView

private struct RecordingTimerView: View {
    let duration: TimeInterval

    private var formatted: String {
        let total = Int(duration)
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text(formatted)
                .font(.system(.title3, design: .monospaced))
                .foregroundStyle(.red)
        }
        .accessibilityLabel(Text("recording_duration \(formatted)"))
    }
}

// MARK: - Preview

#Preview {
    RecordingView()
        .environment(SubscriptionManager())
        .environment(SettingsViewModel())
        .environment(Router())
}
