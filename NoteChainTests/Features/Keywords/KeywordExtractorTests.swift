// NoteChainTests/Features/Keywords/KeywordExtractorTests.swift
// NLTaggerKeywordExtractor の Swift Testing テスト

import Foundation
import Testing
@testable import NoteChain

struct KeywordExtractorTests {

    private let extractor = NLTaggerKeywordExtractor()

    // MARK: - テスト

    /// Given 英語100語のテキスト When extract を呼ぶ Then 3-5件のキーワードが返される
    @Test("英語テキストから 3-5 件のキーワードを抽出する")
    func extractsKeywordsFromEnglishText() {
        let text = """
        The quarterly meeting discussed project deadlines and budget allocation.
        The engineering team presented their roadmap for the new product launch.
        Marketing strategy focused on customer acquisition and retention metrics.
        The CEO emphasized innovation and collaboration across all departments.
        """
        let results = extractor.extract(from: text, maxKeywords: 5)

        #expect(results.count >= 3)
        #expect(results.count <= 5)
        // 全キーワードの信頼度が 0.0-1.0 の範囲内
        for result in results {
            #expect(result.confidence >= 0.0)
            #expect(result.confidence <= 1.0)
        }
    }

    /// Given 日本語テキスト When extract を呼ぶ Then 名詞が抽出される
    @Test("日本語テキストから名詞を抽出する")
    func extractsNounsFromJapaneseText() {
        let text = "今日の会議では新しいプロジェクトの締め切りと予算について話し合いました。チームの戦略と目標を確認しました。"
        let results = extractor.extract(from: text, maxKeywords: 5)

        #expect(!results.isEmpty)
        // ストップワードが含まれていないことを確認
        let keywords = results.map { $0.keyword }
        #expect(!keywords.contains("の"))
        #expect(!keywords.contains("は"))
    }

    /// Given 空文字列 When extract を呼ぶ Then 空配列が返される
    @Test("空文字列から抽出すると空配列を返す")
    func returnsEmptyArrayForEmptyText() {
        let results = extractor.extract(from: "", maxKeywords: 5)
        #expect(results.isEmpty)
    }

    /// Given スペースのみの文字列 When extract を呼ぶ Then 空配列が返される
    @Test("空白のみの文字列から抽出すると空配列を返す")
    func returnsEmptyArrayForWhitespaceText() {
        let results = extractor.extract(from: "   \n\t  ", maxKeywords: 5)
        #expect(results.isEmpty)
    }

    /// Given maxKeywords = 3 When テキストに5つ以上のキーワード候補 Then 最大3件に制限される
    @Test("maxKeywords パラメータが上限を制限する")
    func respectsMaxKeywordsLimit() {
        let text = """
        The project team meeting discussed roadmap strategy timeline budget resources
        engineering marketing product customer acquisition retention innovation collaboration
        """
        let results = extractor.extract(from: text, maxKeywords: 3)
        #expect(results.count <= 3)
    }

    /// Given 信頼度スコア When 降順にソートされている Then 先頭が最高スコア
    @Test("結果が信頼度降順でソートされる")
    func resultsAreSortedByConfidenceDescending() {
        let text = "The engineering team and the engineering department and the engineering roadmap"
        let results = extractor.extract(from: text, maxKeywords: 5)

        guard results.count > 1 else { return }
        for i in 0..<(results.count - 1) {
            #expect(results[i].confidence >= results[i + 1].confidence)
        }
    }

    /// Given スペイン語テキスト When extract を呼ぶ Then キーワードが抽出される
    @Test("スペイン語テキストからキーワードを抽出する")
    func extractsKeywordsFromSpanishText() {
        let text = "La reunión del equipo discutió el proyecto y las estrategias del mercado para el cliente."
        let results = extractor.extract(from: text, maxKeywords: 5)

        #expect(!results.isEmpty)
        // スペイン語ストップワードが除外されていること
        let keywords = results.map { $0.keyword }
        #expect(!keywords.contains("la"))
        #expect(!keywords.contains("el"))
    }
}
