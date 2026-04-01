// NoteChain/Shared/Components/LoadingOverlay.swift
// ローディングオーバーレイコンポーネント

import SwiftUI

/// 処理中を示す半透明オーバーレイ。
/// `.overlay { if isLoading { LoadingOverlay(message: "saving") } }` で使用する。
struct LoadingOverlay: View {

    let messageKey: LocalizedStringKey

    init(message: LocalizedStringKey = "loading") {
        self.messageKey = message
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.2)

                Text(messageKey)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview {
    Color.blue
        .overlay { LoadingOverlay(message: "saving_note") }
}
