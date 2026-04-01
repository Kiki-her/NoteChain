# Subscription モジュール

## 目的

StoreKit 2 を使って月額・年額プランの管理・購入・復元を行う。
`isSubscribed` フラグを @Environment 経由で全モジュールに提供する。
無料枠（週3件）のチェックロジックも担当する。

## ファイル一覧

| ファイル | 役割 |
|---------|------|
| `SubscriptionManager.swift` | StoreKit 2 の状態管理（@MainActor @Observable） |
| `PaywallView.swift` | ペイウォール画面（プラン選択・CTA・復元） |
| `SubscriptionBadgeView.swift` | "Pro" / "Free" バッジコンポーネント |

## 依存関係

- `StoreKit` (system) — Product, Transaction, AppStore
- `UserNotifications` (system) — トライアルリマインダー通知

## StoreKit プロダクト ID

| プラン | プロダクト ID |
|-------|-------------|
| 月額 | com.yourcompany.notechain.pro_monthly |
| 年額 | com.yourcompany.notechain.pro_annual |

## 無料枠ルール

- 週3件まで無料でノート作成可能
- カウントは `SettingsViewModel.weeklyNoteCount` で管理
- `canCreateNote(currentWeekNoteCount:)` でチェック（サーバーレス・オフライン対応）
