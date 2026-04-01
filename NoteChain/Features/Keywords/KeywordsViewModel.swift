// NoteChain/Features/Keywords/KeywordsViewModel.swift
// キーワード表示・フィルタ管理 ViewModel

import Foundation
import SwiftData

/// キーワードバッジ表示とノートフィルタリングを管理する ViewModel。
/// NoteDetailView および NotesListView から参照される。
@MainActor
@Observable
final class KeywordsViewModel {

    // MARK: - 公開プロパティ

    /// 表示するキーワードと信頼度のリスト
    var keywords: [(keyword: String, confidence: Double)] = []

    /// 現在選択中のキーワードフィルタ（nil = 未選択）
    var selectedKeyword: String? = nil

    /// キーワード抽出処理中フラグ
    var isExtracting: Bool = false

    /// エラーメッセージ
    var errorMessage: String? = nil

    // MARK: - 依存注入

    private let extractor: any KeywordExtractorProtocol

    // MARK: - イニシャライザ

    init(extractor: any KeywordExtractorProtocol = KeywordExtractorFactory.create()) {
        self.extractor = extractor
    }

    // MARK: - 公開メソッド

    /// テキストからキーワードを抽出して keywords プロパティを更新する。
    /// - Parameters:
    ///   - text: 抽出対象テキスト
    ///   - maxKeywords: 最大取得件数（デフォルト 5）
    func extractKeywords(from text: String, maxKeywords: Int = 5) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            keywords = []
            return
        }
        isExtracting = true
        defer { isExtracting = false }

        let results = await extractor.extractAsync(from: text, maxKeywords: maxKeywords)
        keywords = results
    }

    /// 既存の Note からキーワードをロードする（再抽出なし）。
    func loadKeywords(from note: Note) {
        keywords = note.topKeywords.map { keyword in
            (keyword: keyword, confidence: note.keywordConfidences[keyword] ?? 0.0)
        }
    }

    /// キーワードを選択/選択解除する。
    func toggleKeyword(_ keyword: String) {
        if selectedKeyword == keyword {
            selectedKeyword = nil
        } else {
            selectedKeyword = keyword
        }
    }

    /// 選択フィルタをクリアする。
    func clearSelection() {
        selectedKeyword = nil
    }

    func clearError() {
        errorMessage = nil
    }
}
