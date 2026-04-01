// NoteChain/Shared/Components/EmptyStateView.swift
// 空状態（ゼロノート・検索結果なし）表示コンポーネント

import SwiftUI

/// リストが空の場合に表示する状態ビュー。
struct EmptyStateView: View {

    let icon: String
    let titleKey: LocalizedStringKey
    let subtitleKey: LocalizedStringKey
    var actionKey: LocalizedStringKey? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(titleKey)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(subtitleKey)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let actionKey, let action {
                Button(actionKey, action: action)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        icon: "note.text",
        titleKey: "empty_notes_title",
        subtitleKey: "empty_notes_subtitle",
        actionKey: "start_recording",
        action: {}
    )
}
