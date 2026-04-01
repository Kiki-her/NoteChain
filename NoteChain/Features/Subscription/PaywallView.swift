// NoteChain/Features/Subscription/PaywallView.swift
// ペイウォール画面 — プラン選択・14日間トライアル CTA・購入復元

import StoreKit
import SwiftUI

/// サブスクリプション購入画面。
/// App Store ガイドライン準拠: 閉じるボタン必須・表示価格は product.displayPrice から取得。
struct PaywallView: View {

    @Environment(SubscriptionManager.self) private var manager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProductID: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダー
                    paywallHeader

                    // 機能リスト
                    featureList

                    // 商品ローディング / プラン選択
                    if manager.isLoading && manager.products.isEmpty {
                        ProgressView()
                            .padding()
                    } else {
                        productOptions
                    }

                    // CTA ボタン
                    ctaButton

                    // 法的リンク
                    legalLinks
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // CRITICAL: 閉じるボタン必須（App Store ガイドライン 3.1.1）
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(Text("close_button"))
                }
            }
        }
        .task {
            if manager.products.isEmpty {
                await manager.fetchProducts()
            }
            // デフォルトで年額プランを選択
            selectedProductID = manager.products.first {
                $0.id.contains("annual")
            }?.id ?? manager.products.first?.id
        }
        .alert(
            "error_title",
            isPresented: Binding(
                get: { manager.errorMessage != nil },
                set: { if !$0 { manager.clearError() } }
            )
        ) {
            Button("ok_button", role: .cancel) { manager.clearError() }
        } message: {
            if let msg = manager.errorMessage { Text(msg) }
        }
    }

    // MARK: - ヘッダー

    private var paywallHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(.linearGradient(
                    colors: [.purple, .indigo],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .accessibilityHidden(true)

            Text("paywall_title")
                .font(.title2.bold())

            Text("paywall_subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - 機能リスト

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 12) {
            FeatureRow(icon: "infinity", labelKey: "feature_unlimited_notes")
            FeatureRow(icon: "wand.and.stars", labelKey: "feature_ai_keywords")
            FeatureRow(icon: "magnifyingglass", labelKey: "feature_full_search")
            FeatureRow(icon: "clock", labelKey: "feature_unlimited_storage")
            FeatureRow(icon: "icloud", labelKey: "feature_icloud_soon")
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - プラン選択

    private var productOptions: some View {
        VStack(spacing: 12) {
            ForEach(manager.products) { product in
                ProductOptionButton(
                    product: product,
                    isSelected: selectedProductID == product.id,
                    isRecommended: product.id.contains("annual")
                ) {
                    selectedProductID = product.id
                }
            }
        }
    }

    // MARK: - CTA ボタン

    private var ctaButton: some View {
        VStack(spacing: 8) {
            Button {
                Task {
                    guard let product = manager.products.first(
                        where: { $0.id == selectedProductID }
                    ) else { return }
                    do {
                        try await manager.purchase(product)
                        if manager.isSubscribed { dismiss() }
                    } catch {
                        // エラーは manager.errorMessage に設定済み
                    }
                }
            } label: {
                Group {
                    if manager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("paywall_cta_button")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            }
            .buttonStyle(.borderedProminent)
            .disabled(manager.isLoading || selectedProductID == nil)
            .tint(.purple)

            Text("paywall_trial_disclaimer")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - 法的リンク

    private var legalLinks: some View {
        VStack(spacing: 8) {
            Button("restore_purchases_button") {
                Task { await manager.restorePurchases() }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Link("privacy_policy_label",
                     destination: URL(string: "https://notechain.app/privacy")!)
                Link("terms_of_service_label",
                     destination: URL(string: "https://notechain.app/terms")!)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - FeatureRow

private struct FeatureRow: View {
    let icon: String
    let labelKey: LocalizedStringKey

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(.purple)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(labelKey)
                .font(.subheadline)
        }
    }
}

// MARK: - ProductOptionButton

private struct ProductOptionButton: View {
    let product: Product
    let isSelected: Bool
    let isRecommended: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(product.displayName)
                            .font(.headline)
                        if isRecommended {
                            Text("recommended_badge")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.orange, in: Capsule())
                        }
                    }
                    // ALWAYS: 表示価格は product.displayPrice から取得
                    Text(product.displayPrice)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .purple : .secondary)
            }
            .padding()
            .background(
                isSelected ? .purple.opacity(0.1) : Color(.systemBackground),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color(.systemGray4), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
        .environment(SubscriptionManager.preview)
}
