// NoteChain/Features/NotesList/NotesListViewModel.swift
// ノート一覧の状態管理 ViewModel

import Foundation
import SwiftData

/// ノート一覧の検索・ソート・フィルタ・削除を管理する ViewModel。
@MainActor
@Observable
final class NotesListViewModel {

    // MARK: - 公開プロパティ

    var searchText: String = ""
    var sortOrder: SortOrder = .newestFirst
    var languageFilter: String? = nil
    var keywordFilter: String? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // MARK: - 依存注入

    private let modelContext: ModelContext

    // MARK: - イニシャライザ

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - 計算プロパティ

    /// 検索・フィルタ・ソートを適用したノートリスト
    var filteredNotes: [Note] {
        let descriptor = FetchDescriptor<Note>(
            sortBy: [sortOrder.sortDescriptor]
        )
        let allNotes = (try? modelContext.fetch(descriptor)) ?? []

        return allNotes.filter { note in
            let matchesSearch = searchText.isEmpty
                || note.transcript.localizedCaseInsensitiveContains(searchText)
                || note.keywords.contains { $0.localizedCaseInsensitiveContains(searchText) }

            let matchesLanguage = languageFilter == nil
                || note.languageCode == languageFilter

            let matchesKeyword = keywordFilter == nil
                || note.keywords.contains { $0.localizedCaseInsensitiveContains(keywordFilter!) }

            return matchesSearch && matchesLanguage && matchesKeyword
        }
    }

    /// 日付（sectionDate）でグループ化したノートの Dictionary
    var groupedNotes: [Date: [Note]] {
        Dictionary(grouping: filteredNotes) { $0.sectionDate }
    }

    /// グループ化の日付キーを新しい順に並べた配列
    var sortedSectionDates: [Date] {
        groupedNotes.keys.sorted(by: >)
    }

    // MARK: - 公開メソッド

    /// 指定インデックスのノートを削除する。
    /// - Parameters:
    ///   - offsets: List の IndexSet
    ///   - sectionDate: 対象セクションの日付
    func deleteNotes(at offsets: IndexSet, in sectionDate: Date) {
        guard let notes = groupedNotes[sectionDate] else { return }
        let toDelete = offsets.map { notes[$0] }
        for note in toDelete {
            modelContext.delete(note)
        }
        do {
            try modelContext.save()
        } catch {
            errorMessage = AppError.noteDeleteFailed(error.localizedDescription).errorDescription
        }
    }

    /// お気に入りトグル。
    func toggleFavorite(_ note: Note) {
        note.isFavorite.toggle()
        note.updatedAt = Date()
        try? modelContext.save()
    }

    /// キーワードフィルタを適用する。
    func applyKeywordFilter(_ keyword: String) {
        keywordFilter = keyword
        searchText = ""
    }

    /// 全フィルタをクリアする。
    func clearFilters() {
        searchText = ""
        languageFilter = nil
        keywordFilter = nil
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - SortOrder

    enum SortOrder: String, CaseIterable, Identifiable {
        case newestFirst  = "sort_newest"
        case oldestFirst  = "sort_oldest"
        case longestFirst = "sort_longest"
        case mostKeywords = "sort_most_keywords"

        var id: String { rawValue }

        var localizedLabel: LocalizedStringKey { LocalizedStringKey(rawValue) }

        var sortDescriptor: SortDescriptor<Note> {
            switch self {
            case .newestFirst:
                SortDescriptor(\.createdAt, order: .reverse)
            case .oldestFirst:
                SortDescriptor(\.createdAt, order: .forward)
            case .longestFirst:
                SortDescriptor(\.duration, order: .reverse)
            case .mostKeywords:
                // SwiftData では配列の count でソートできないため createdAt でフォールバック
                SortDescriptor(\.createdAt, order: .reverse)
            }
        }
    }
}
