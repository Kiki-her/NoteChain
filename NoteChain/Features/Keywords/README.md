# Keywords モジュール

## 目的

NaturalLanguage フレームワーク（NLTagger）を使ってテキストから
重要キーワードを自動抽出し、バッジ UI として表示する Feature モジュール。

## 責務

- テキストから名詞・固有名詞を NLTagger で抽出する
- 出現頻度によるスコアリングで最重要キーワードをランキングする
- NLLanguageRecognizer で言語を自動検出し多言語対応する
- キーワードをカプセル形バッジとして表示する UI コンポーネントを提供する

## ファイル一覧

| ファイル | 役割 |
|---------|------|
| `KeywordExtractor.swift` | プロトコル + NLTagger実装 + Factory + Mock |
| `KeywordBadgeView.swift` | キーワードバッジ表示コンポーネント |

## 依存関係

- `NaturalLanguage` (system framework) — NLTagger, NLLanguageRecognizer
- `Shared/Models/Note` — 抽出結果の書き込み先
- 他モジュールから `KeywordExtractorProtocol` 経由で使用される

## v1.1 拡張ポイント

`KeywordExtractorProtocol` の別実装として `CoreMLKeywordExtractor` を追加するだけで、
`KeywordExtractorFactory.create()` の戻り値を変えるだけで差し替え可能。
