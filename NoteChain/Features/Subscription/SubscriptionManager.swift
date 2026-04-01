// NoteChain/Features/Subscription/SubscriptionManager.swift
// StoreKit 2 サブスクリプション管理

import Foundation
import StoreKit
import UserNotifications

/// StoreKit 2 を使ってサブスクリプションを管理する ViewModel。
/// アプリ起動時に `initialize()` を呼び、@Environment で全 Feature から参照する。
@MainActor
@Observable
final class SubscriptionManager {

    // MARK: - 公開プロパティ

    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isSubscribed: Bool = false
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var subscriptionExpirationDate: Date? = nil
    var daysRemainingInTrial: Int? = nil

    // MARK: - 内部状態

    private var transactionListenerTask: Task<Void, Never>?

    // MARK: - 定数

    static let productIDs: [String] = [
        "com.yourcompany.notechain.pro_monthly",
        "com.yourcompany.notechain.pro_annual"
    ]

    // MARK: - イニシャライザ / クリーンアップ

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - 公開メソッド

    /// 起動時に呼ぶ初期化処理。商品取得・購入状態更新・トランザクション監視を開始する。
    func initialize() async {
        // CRITICAL: Transaction.updates の監視を最初に開始する
        transactionListenerTask = observeTransactionUpdates()
        await fetchProducts()
        await updatePurchasedProducts()
        await calculateTrialDaysRemaining()
    }

    /// App Store から商品リストを取得する。
    func fetchProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: Self.productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            errorMessage = AppError.productFetchFailed(error.localizedDescription).errorDescription
        }
    }

    /// 指定商品を購入する。
    func purchase(_ product: Product) async throws {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            // CRITICAL: payloadValue で署名検証を行う
            let transaction = try verification.payloadValue
            await updatePurchasedProducts()
            // CRITICAL: transaction.finish() を必ず呼ぶ
            await transaction.finish()

        case .userCancelled:
            break  // ユーザーキャンセルは正常（エラーではない）

        case .pending:
            break  // 保護者承認待ちなど（トランザクション更新で後ほど処理）

        @unknown default:
            break
        }
    }

    /// 購入を復元する。
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            // ALWAYS: AppStore.sync() で復元する（SKPaymentQueue は使わない）
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            errorMessage = AppError.restorePurchaseFailed(error.localizedDescription).errorDescription
        }
    }

    /// 無料枠チェック。サーバーレスでオフライン対応。
    func canCreateNote(currentWeekNoteCount: Int) -> Bool {
        isSubscribed || currentWeekNoteCount < 3
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - 内部メソッド

    /// 現在有効な購入済み商品を更新する。
    private func updatePurchasedProducts() async {
        var newPurchasedIDs: Set<String> = []
        var latestExpiration: Date? = nil

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? result.payloadValue else { continue }
            if transaction.revocationDate == nil {
                newPurchasedIDs.insert(transaction.productID)
                if let expDate = transaction.expirationDate {
                    latestExpiration = max(latestExpiration ?? expDate, expDate)
                }
            }
        }

        purchasedProductIDs = newPurchasedIDs
        isSubscribed = !purchasedProductIDs.isEmpty
        subscriptionExpirationDate = latestExpiration
    }

    /// トランザクション更新を非同期で監視する（払い戻し・更新など外部変更に対応）。
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { break }
                guard let transaction = try? result.payloadValue else { continue }
                await self.updatePurchasedProducts()
                await transaction.finish()
            }
        }
    }

    /// トライアル残日数を計算する。
    private func calculateTrialDaysRemaining() async {
        guard let expDate = subscriptionExpirationDate else {
            daysRemainingInTrial = nil
            return
        }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expDate).day ?? 0
        daysRemainingInTrial = days > 0 ? days : nil
    }

    /// トライアルリマインダー通知をスケジュールする（Day 2/7/13）。
    func scheduleTrialReminders() async {
        guard let expDate = subscriptionExpirationDate else { return }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        let reminders: [(daysBeforeEnd: Int, titleKey: String, bodyKey: String)] = [
            (12, "notification_trial_day2_title", "notification_trial_day2_body"),
            (7,  "notification_trial_day7_title",  "notification_trial_day7_body"),
            (1,  "notification_trial_day13_title", "notification_trial_day13_body"),
        ]

        for reminder in reminders {
            guard let fireDate = Calendar.current.date(
                byAdding: .day,
                value: -reminder.daysBeforeEnd,
                to: expDate
            ), fireDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = String(localized: LocalizedStringResource(stringLiteral: reminder.titleKey))
            content.body = String(localized: LocalizedStringResource(stringLiteral: reminder.bodyKey))
            content.sound = .default

            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(
                identifier: "trial_reminder_\(reminder.daysBeforeEnd)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }
}

// MARK: - Preview ヘルパー

extension SubscriptionManager {
    /// Preview や テスト用のインスタンス
    static var preview: SubscriptionManager {
        let manager = SubscriptionManager()
        manager.isSubscribed = false
        return manager
    }
}
