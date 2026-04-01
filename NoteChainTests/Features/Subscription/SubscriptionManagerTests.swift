// NoteChainTests/Features/Subscription/SubscriptionManagerTests.swift
// SubscriptionManager の Swift Testing テスト（StoreKit テスト環境）

import Foundation
import StoreKit
import Testing
@testable import NoteChain

@MainActor
struct SubscriptionManagerTests {

    // MARK: - テスト

    /// Given isSubscribed が false、currentWeekNoteCount が 2
    /// When canCreateNote を呼ぶ Then true が返される（無料枠内）
    @Test("無料枠内（週2件）では canCreateNote が true")
    func canCreateNoteWithinFreeLimit() {
        let sut = SubscriptionManager()
        sut.isSubscribed = false
        #expect(sut.canCreateNote(currentWeekNoteCount: 2) == true)
    }

    /// Given isSubscribed が false、currentWeekNoteCount が 3
    /// When canCreateNote を呼ぶ Then false が返される（無料枠超過）
    @Test("無料枠超過（週3件以上）では canCreateNote が false")
    func cannotCreateNoteWhenFreeLimitExceeded() {
        let sut = SubscriptionManager()
        sut.isSubscribed = false
        #expect(sut.canCreateNote(currentWeekNoteCount: 3) == false)
    }

    /// Given isSubscribed が true、currentWeekNoteCount が 100
    /// When canCreateNote を呼ぶ Then true が返される（サブスク有効）
    @Test("サブスク有効時は週制限なく canCreateNote が true")
    func subscribedUserCanAlwaysCreateNote() {
        let sut = SubscriptionManager()
        sut.isSubscribed = true
        #expect(sut.canCreateNote(currentWeekNoteCount: 100) == true)
    }

    /// Given preview インスタンス When isSubscribed を確認 Then false
    @Test("preview インスタンスは未購読状態")
    func previewInstanceIsNotSubscribed() {
        let sut = SubscriptionManager.preview
        #expect(sut.isSubscribed == false)
    }

    /// Given productIDs When 件数確認 Then 2件（月額・年額）
    @Test("productIDs に 2 件の商品 ID が含まれる")
    func productIDsContainsTwoProducts() {
        #expect(SubscriptionManager.productIDs.count == 2)
        #expect(SubscriptionManager.productIDs.contains("com.yourcompany.notechain.pro_monthly"))
        #expect(SubscriptionManager.productIDs.contains("com.yourcompany.notechain.pro_annual"))
    }

    /// Given エラーが設定されている When clearError を呼ぶ Then nil になる
    @Test("clearError でエラーメッセージがクリアされる")
    func clearErrorResetsErrorMessage() {
        let sut = SubscriptionManager()
        sut.errorMessage = "Some error"
        sut.clearError()
        #expect(sut.errorMessage == nil)
    }
}
