// NoteChain/Features/NotesList/NoteDetailViewModel.swift
// ノート詳細・編集の状態管理 ViewModel

import Foundation
import SwiftData

/// ノート詳細画面の状態を管理する ViewModel。
/// インライン編集・キーワード追加削除・キーワード再抽出・お気に入り・削除を担う。
@MainActor
@Observable
final class NoteDetailViewModel {

    // MARK: - 公開プロパティ

    var note: Note? = nil
    var isEditing: Bool = false
    var editingTranscript: String = ""
    var isExtractingKeywords: Bool = false
    var newKeywordText: String = ""
    var errorMessage: String? = nil
    var isDeleted: Bool = false

    // MARK: - 依存注入

    private let modelContext: ModelContext
    private let keywordExtractor: any KeywordExtractorProtocol
    private let noteID: UUID

    // MARK: - イニシャライザ

    init(
        noteID: UUID,
        modelContext: ModelContext,
        keywordExtractor: any KeywordExtractorProtocol = KeywordExtractorFactory.create()
    ) {
        self.noteID = noteID
        self.modelContext = modelContext
        self.keywordExtractor = keywordExtractor
    }

    // MARK: - 公開メソッド

    /// Note を SwiftData からフェッチする。
    func loadNote() {
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate { $0.id == noteID }
        )
        note = (try? modelContext.fetch(descriptor))?.first
    }

    /// 編集モードを開始する。
    func startEditing() {
        guard let note else { return }
        editingTranscript = note.transcript
        isEditing = true
    }

    /// 編集内容を保存してキーワードを再抽出する。
    func saveEdit() async {
        guard let note else { return }
        note.transcript = editingTranscript
        note.updatedAt = Date()
        isEditing = false

        // キーワード再抽出
        await reExtractKeywords()

        do {
            try modelContext.save()
        } catch {
            errorMessage = AppError.swiftDataSaveFailed(error.localizedDescription).errorDescription
        }
    }

    /// 編集をキャンセルする。
    func cancelEdit() {
        isEditing = false
        editingTranscript = ""
    }

    /// キーワードを手動追加する。
    func addKeyword(_ keyword: String) {
        guard let note else { return }
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty, !note.keywords.contains(trimmed) else { return }
        note.keywords.append(trimmed)
        note.keywordConfidences[trimmed] = 1.0  // 手動追加は信頼度 1.0
        note.updatedAt = Date()
        newKeywordText = ""
        try? modelContext.save()
    }

    /// キーワードを削除する。
    func removeKeyword(_ keyword: String) {
        guard let note else { return }
        note.keywords.removeAll { $0 == keyword }
        note.keywordConfidences.removeValue(forKey: keyword)
        note.updatedAt = Date()
        try? modelContext.save()
    }

    /// transcript を再解析してキーワードを更新する。
    func reExtractKeywords() async {
        guard let note, !note.transcript.isEmpty else { return }
        isExtractingKeywords = true
        defer { isExtractingKeywords = false }

        let extracted = await keywordExtractor.extractAsync(from: note.transcript, maxKeywords: 5)
        note.keywords = extracted.map { $0.keyword }
        note.keywordConfidences = Dictionary(
            uniqueKeysWithValues: extracted.map { ($0.keyword, $0.confidence) }
        )
    }

    /// お気に入りをトグルする。
    func toggleFavorite() {
        guard let note else { return }
        note.isFavorite.toggle()
        note.updatedAt = Date()
        try? modelContext.save()
    }

    /// Note を削除する。
    func deleteNote() {
        guard let note else { return }
        modelContext.delete(note)
        do {
            try modelContext.save()
            isDeleted = true
        } catch {
            errorMessage = AppError.noteDeleteFailed(error.localizedDescription).errorDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
