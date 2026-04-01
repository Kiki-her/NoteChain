// NoteChain/Features/Subscription/SubscriptionBadgeView.swift
// サブスクリプション状態バッジコンポーネント

import SwiftUI

/// 現在のサブスクリプション状態を小型バッジで表示する。
/// Settings 画面や プロフィール等で使用する。
struct SubscriptionBadgeView: View {

    @Environment(SubscriptionManager.self) private var subscriptionManager

    var body: some View {
        Group {
            if subscriptionManager.isSubscribed {
                proBadge
            } else {
                freeBadge
            }
        }
    }

    private var proBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.caption2)
                .accessibilityHidden(true)
            Text("Pro")
                .font(.caption.bold())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(.linearGradient(
            colors: [.purple, .indigo],
            startPoint: .leading,
            endPoint: .trailing
        ), in: Capsule())
        .accessibilityLabel(Text("subscription_pro_badge"))
    }

    private var freeBadge: some View {
        Text("Free")
            .font(.caption.bold())
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.secondary.opacity(0.15), in: Capsule())
            .accessibilityLabel(Text("subscription_free_badge"))
    }
}

#Preview {
    VStack(spacing: 16) {
        SubscriptionBadgeView()
            .environment(SubscriptionManager.preview)

        let proManager = SubscriptionManager()
        let _ = { proManager.isSubscribed = true }()
        SubscriptionBadgeView()
            .environment(proManager)
    }
    .padding()
}
