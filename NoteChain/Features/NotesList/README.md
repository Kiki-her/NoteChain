# NotesList モジュール

## 目的

SwiftData から Note を取得し、検索・ソート・日付セクション区切りでリスト表示する。
ノートの詳細表示・インライン編集・削除もこのモジュールが担当する。

## ファイル一覧

| ファイル | 役割 |
|---------|------|
| `NotesListView.swift` | ノート一覧（検索バー・ソートメニュー・セクション区切り） |
| `NotesListViewModel.swift` | 検索・ソート・削除の状態管理 |
| `NoteRowView.swift` | リスト行コンポーネント（タイトル・バッジ・時刻・時間） |
| `NoteDetailView.swift` | ノート詳細・編集・キーワード管理 |
| `NoteDetailViewModel.swift` | 詳細画面の状態管理 |

## 依存関係

- `Shared/Models/Note` — SwiftData フェッチ・更新・削除
- `Shared/Navigation/Router` — 詳細画面への push 遷移
- `Features/Keywords/KeywordBadgeView` — バッジ表示
- `Features/Keywords/KeywordExtractor` — 詳細画面でのキーワード再抽出
- `Shared/Components/EmptyStateView` — 0件時の空状態

## 設計上の注意

- `@Query` マクロは使用しない。`ModelContext.fetch(FetchDescriptor<Note>)` を ViewModel で呼ぶ
- `groupedNotes` は `Dictionary(grouping:by:)` で `sectionDate` をキーにする
- キーワードフィルタは `languageFilter` とは別の `keywordFilter` プロパティで管理する
