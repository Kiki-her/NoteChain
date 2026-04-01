// NoteChain/Shared/Components/PermissionDeniedView.swift
// マイク・音声認識権限が拒否されている場合の案内ビュー

import SwiftUI

/// 権限が拒否されている場合に「設定を開く」ボタン付きで案内するビュー。
struct PermissionDeniedView: View {

    enum PermissionType {
        case microphone
        case speechRecognition

        var iconName: String {
            switch self {
            case .microphone: "mic.slash.fill"
            case .speechRecognition: "waveform.slash"
            }
        }

        var titleKey: LocalizedStringKey {
            switch self {
            case .microphone: "permission_mic_denied_title"
            case .speechRecognition: "permission_speech_denied_title"
            }
        }

        var bodyKey: LocalizedStringKey {
            switch self {
            case .microphone: "permission_mic_denied_body"
            case .speechRecognition: "permission_speech_denied_body"
            }
        }
    }

    let type: PermissionType

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: type.iconName)
                .font(.system(size: 40))
                .foregroundStyle(.red)
                .accessibilityHidden(true)

            Text(type.titleKey)
                .font(.headline)

            Text(type.bodyKey)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("open_settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

#Preview {
    VStack(spacing: 24) {
        PermissionDeniedView(type: .microphone)
        PermissionDeniedView(type: .speechRecognition)
    }
    .padding()
}
