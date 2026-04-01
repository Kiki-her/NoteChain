// NoteChain/Features/Settings/LanguagePickerView.swift
// 録音言語選択ピッカー

import SwiftUI

/// 録音言語をフラグ付きリストで選択するコンポーネント。
struct LanguagePickerView: View {

    @Binding var selectedLanguage: String

    var body: some View {
        List {
            ForEach(SettingsViewModel.supportedRecordingLanguages, id: \.code) { language in
                Button {
                    selectedLanguage = language.code
                } label: {
                    HStack {
                        Text(language.flag)
                            .font(.title2)
                            .accessibilityHidden(true)

                        Text(language.name)
                            .foregroundStyle(.primary)

                        Spacer()

                        if selectedLanguage == language.code {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.accentColor)
                                .accessibilityHidden(true)
                        }
                    }
                }
            }
        }
        .navigationTitle("recording_language_picker_title")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LanguagePickerView(selectedLanguage: .constant("en-US"))
    }
}
