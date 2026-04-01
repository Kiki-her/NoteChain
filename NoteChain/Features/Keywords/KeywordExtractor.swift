// NoteChain/Features/Keywords/KeywordExtractor.swift
// NLTagger ベースのキーワード抽出 — MVP 完全実装

import Foundation
import NaturalLanguage

// MARK: - KeywordExtractorProtocol

/// キーワード抽出サービスの共通インターフェース。
/// MVP では NLTaggerKeywordExtractor が実装する。
/// v1.1 では CoreMLKeywordExtractor を追加して差し替え可能。
protocol KeywordExtractorProtocol: Sendable {

    /// テキストからキーワードを同期的に抽出する。
    /// - Parameters:
    ///   - text: 抽出対象テキスト
    ///   - maxKeywords: 最大取得件数（デフォルト 5）
    /// - Returns: （キーワード, 信頼度スコア 0.0-1.0）のタプル配列。信頼度降順。
    func extract(from text: String, maxKeywords: Int) -> [(keyword: String, confidence: Double)]
}

extension KeywordExtractorProtocol {

    /// テキストからキーワードを非同期で抽出する（CPU バウンド処理をバックグラウンドに退避）。
    func extractAsync(
        from text: String,
        maxKeywords: Int = 5
    ) async -> [(keyword: String, confidence: Double)] {
        await Task.detached(priority: .userInitiated) {
            self.extract(from: text, maxKeywords: maxKeywords)
        }.value
    }
}

// MARK: - NLTaggerKeywordExtractor

/// NaturalLanguage フレームワークを使ったキーワード抽出実装（MVP）。
///
/// 処理フロー:
/// 1. NLLanguageRecognizer で支配的言語を検出
/// 2. NLTagger で品詞タグ付け（名詞・固有名詞を対象）
/// 3. 出現頻度でスコアリング（最大頻度を 1.0 として正規化）
/// 4. 信頼度降順でソートして maxKeywords 件を返す
final class NLTaggerKeywordExtractor: KeywordExtractorProtocol {

    func extract(
        from text: String,
        maxKeywords: Int = 5
    ) -> [(keyword: String, confidence: Double)] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        // 1. 言語検出
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(trimmed)
        let language = recognizer.dominantLanguage ?? .english

        // 2. NLTagger 設定
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
        tagger.string = trimmed
        tagger.setLanguage(language, range: trimmed.startIndex..<trimmed.endIndex)

        var wordFrequency: [String: Int] = [:]
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]

        // 3. 名詞・固有名詞の収集
        // lexicalClass で名詞を取得
        tagger.enumerateTags(
            in: trimmed.startIndex..<trimmed.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: options
        ) { tag, tokenRange in
            guard let tag else { return true }
            let targetTags: [NLTag] = [.noun]
            if targetTags.contains(tag) {
                let word = String(trimmed[tokenRange]).lowercased()
                if word.count > 1, !Self.stopWords.contains(word) {
                    wordFrequency[word, default: 0] += 1
                }
            }
            return true
        }

        // nameType で固有名詞（人名・地名・組織名）を収集（追加ボーナス）
        tagger.enumerateTags(
            in: trimmed.startIndex..<trimmed.endIndex,
            unit: .word,
            scheme: .nameType,
            options: options
        ) { tag, tokenRange in
            guard let tag else { return true }
            let namedEntityTags: [NLTag] = [.personalName, .placeName, .organizationName]
            if namedEntityTags.contains(tag) {
                let word = String(trimmed[tokenRange]).lowercased()
                if word.count > 1, !Self.stopWords.contains(word) {
                    // 固有名詞はボーナス加算（重要度が高いため）
                    wordFrequency[word, default: 0] += 2
                }
            }
            return true
        }

        guard !wordFrequency.isEmpty else { return [] }

        // 4. 頻度スコアの正規化（最大頻度を 1.0 とする）
        let maxFreq = Double(wordFrequency.values.max() ?? 1)
        let results = wordFrequency
            .map { (keyword: $0.key, confidence: Double($0.value) / maxFreq) }
            .sorted { $0.confidence > $1.confidence }
            .prefix(maxKeywords)
            .map { $0 }

        return results
    }

    // MARK: - ストップワード辞書

    /// 抽出から除外する一般的な単語（英語・日本語・スペイン語）。
    static let stopWords: Set<String> = [
        // English — articles, pronouns, auxiliaries
        "the", "a", "an", "is", "are", "was", "were", "be", "been", "being",
        "have", "has", "had", "do", "does", "did", "will", "would", "could",
        "should", "may", "might", "shall", "can", "need", "dare", "ought",
        "this", "that", "these", "those", "here", "there", "where", "when",
        "i", "you", "he", "she", "it", "we", "they", "me", "him", "her",
        "us", "them", "my", "your", "his", "its", "our", "their",
        "what", "which", "who", "whom", "whose", "how", "why",
        "and", "or", "but", "nor", "so", "for", "yet", "both", "either",
        "just", "also", "very", "really", "quite", "too", "already",
        "now", "then", "time", "way", "day", "year", "thing", "something",
        "anything", "everything", "nothing", "someone", "anyone", "everyone",
        "about", "above", "across", "after", "against", "along", "among",
        "around", "at", "before", "behind", "below", "between", "beyond",
        "by", "down", "during", "except", "from", "in", "inside", "into",
        "like", "near", "of", "off", "on", "out", "outside", "over",
        "since", "through", "to", "toward", "under", "until", "up", "with",
        // 日本語 — 助詞・助動詞・一般的な動詞・指示語
        "の", "に", "は", "を", "た", "が", "で", "て", "と", "し",
        "れ", "さ", "ある", "いる", "する", "も", "な", "こと", "もの",
        "ため", "から", "まで", "より", "だ", "です", "ます", "ない",
        "この", "その", "あの", "どの", "これ", "それ", "あれ", "どれ",
        "ここ", "そこ", "あそこ", "どこ", "いま", "もう", "また", "まだ",
        "とても", "少し", "多い", "少ない", "大きい", "小さい", "良い", "悪い",
        // Spanish — artículos, pronombres, preposiciones, verbos auxiliares
        "el", "la", "los", "las", "un", "una", "unos", "unas",
        "de", "del", "en", "que", "y", "a", "por", "con", "para",
        "es", "no", "se", "al", "lo", "le", "su", "sus", "mi", "mis",
        "yo", "tú", "él", "ella", "nosotros", "vosotros", "ellos", "ellas",
        "me", "te", "nos", "os", "este", "esta", "estos", "estas",
        "ese", "esa", "esos", "esas", "aquel", "aquella",
        "hay", "ser", "estar", "tener", "hacer", "poder", "ir", "ver",
        "más", "muy", "bien", "aquí", "allí", "ahora", "ya", "también",
        "pero", "porque", "cuando", "donde", "como", "si", "todo", "todos"
    ]
}

// MARK: - KeywordExtractorFactory

/// 使用する実装を選択するファクトリ。
/// v1.1 で Core ML モデルが用意されたら `CoreMLKeywordExtractor` を返すよう変更する。
enum KeywordExtractorFactory {
    static func create() -> any KeywordExtractorProtocol {
        // v1.1: if coreMLModelAvailable { return CoreMLKeywordExtractor() }
        return NLTaggerKeywordExtractor()
    }
}

// MARK: - MockKeywordExtractor（テスト用）

/// テスト用モック実装。固定のキーワードを返す。
final class MockKeywordExtractor: KeywordExtractorProtocol {

    var mockResults: [(keyword: String, confidence: Double)] = [
        (keyword: "meeting", confidence: 1.0),
        (keyword: "project", confidence: 0.8),
        (keyword: "deadline", confidence: 0.6)
    ]

    func extract(
        from text: String,
        maxKeywords: Int
    ) -> [(keyword: String, confidence: Double)] {
        Array(mockResults.prefix(maxKeywords))
    }
}
