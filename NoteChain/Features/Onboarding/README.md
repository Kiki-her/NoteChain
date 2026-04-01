# Onboarding モジュール

## 概要
アプリ初回起動時の権限リクエストとアプリ紹介を担当するモジュール。
`fullScreenCover` で表示され、完了後は ContentView のメイン画面に切り替わる。

## ファイル構成

```
NoteChain/Features/Onboarding/
├── README.md                 # このファイル
├── OnboardingView.swift      # オンボーディング画面（3ステップ PageStyle TabView）
└── OnboardingViewModel.swift # ページ進行・権限リクエスト管理 ViewModel
```

## 責務

- 3ステップのスライドで録音・キーワード・プライバシーの価値提案を提示
- マイク権限・音声認識権限のリクエスト
- `hasCompletedOnboarding` フラグを AppState/SettingsViewModel に書き込み
- オンボーディング完了後の ContentView への遷移トリガー

## 遷移フロー

```
アプリ初回起動
  └─ fullScreenCover → OnboardingView（Page 0 → 1 → 2）
       └─ 完了ボタン → AppState.completeOnboarding()
            └─ ContentView（TabView）に切り替わる
```

## 依存関係

- **依存先**: Shared/Models（AppError）、AppState
- **依存元**: ContentView（fullScreenCover 条件）

## 受け入れ基準（Given-When-Then）

- **Given** アプリが初回起動 **When** OnboardingView が表示される **Then** ページ 0 から始まり権限リクエストが発生する
- **Given** ページ 2 が表示されている **When** "Get Started" を押す **Then** hasCompletedOnboarding が true になり ContentView が表示される
- **Given** マイク権限が拒否されている **When** オンボーディングを完了する **Then** 録音画面に PermissionDeniedView が表示される
