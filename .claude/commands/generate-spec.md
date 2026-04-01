# /generate-spec [feature]

指定された機能の仕様書を `docs/specs/[feature].md` に生成します。

## 入力

`[feature]`: recording / keywords / notes-list / settings / subscription

## 実行手順

1. `docs/PRD.md` の該当機能セクションを読む
2. `docs/specs/template.md` のテンプレートを読む
3. 以下の内容で `docs/specs/[feature].md` を生成する

## 生成内容

```markdown
# [Feature Name] 機能仕様書

## 概要
（1-2文で機能の目的を説明）

## ユーザーフロー
（PRD のフロー図を基に記述）

## 画面・コンポーネント一覧
（View ファイルと役割）

## ViewModel API
（公開プロパティ・メソッドの一覧）

## データモデル
（使用する @Model とプロパティ）

## エラーケース
（AppError の該当ケース）

## 受け入れ基準（Given-When-Then）
（PRD の受け入れ基準を転記・補足）

## 依存モジュール
（Shared サービス・他 Feature への依存）
```

## 注意

生成後、人間のレビューを受けてから実装に進むこと。
