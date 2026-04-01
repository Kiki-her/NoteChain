---
description: "StoreKit 2 規約"
paths:
  - "**/Subscription/**/*.swift"
---

# NoteChain — StoreKit 2 ルール

## トランザクション処理

CRITICAL: アプリ起動時に必ず `Transaction.updates` の非同期ループを開始する。
          払い戻し・サブスク失効など外部からのトランザクション更新を処理するため。
          ```swift
          Task.detached {
              for await result in Transaction.updates { ... }
          }
          ```

CRITICAL: `VerificationResult` は必ず `.payloadValue` で署名検証を行う。
          `.unsafePayloadValue` は絶対に使用禁止（検証なしでトランザクションを受け入れる）。

CRITICAL: 購入完了後は必ず `await transaction.finish()` を呼ぶ。
          呼ばないと App Store がトランザクションを再配信し続ける。

## 価格表示

ALWAYS:   表示価格は `product.displayPrice` を使う。
          価格のハードコード（"$3.99" など）は App Store ガイドライン違反。

## 購入フロー

ALWAYS:   購入処理中は `isLoading = true` にしてボタンを無効化し、多重購入を防ぐ。
          `defer { isLoading = false }` パターンを活用する。

## 購入復元

ALWAYS:   購入復元は `AppStore.sync()` のみを使う。
          `SKPaymentQueue.restoreCompletedTransactions()` は StoreKit 1 API で非推奨。

## プロダクト ID

ALWAYS:   プロダクト ID は `SubscriptionManager.productIDs` 静的配列で一元管理する。
          コード中に文字列リテラルで直接書くことを禁止。

## ペイウォール UX

CRITICAL: ペイウォール画面には必ず閉じるボタン（dismiss）を設置する。
          購入を強制するペイウォールは App Store ガイドライン 3.1.1 違反。

## 無料枠チェック

ALWAYS:   `canCreateNote(currentWeekNoteCount:)` は `@AppStorage` のローカル値のみで判定する。
          外部サーバー検証なし（オフライン動作のため）。
