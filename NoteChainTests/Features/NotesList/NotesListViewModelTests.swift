// NoteChainTests/Features/NotesList/NotesListViewModelTests.swift
// NotesListViewModel の Swift Testing テスト

import Foundation
import SwiftData
import Testing
@testable import NoteChain

@MainActor
struct NotesListViewModelTests {

    // MARK: - ヘルパー

    private func makeViewModel() throws -> (NotesListViewModel, ModelContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Note.self, configurations: config)
        let context = container.mainContext
        return (NotesListViewModel(modelContext: context), context)
    }

    private func insertNote(
        transcript: String,
        keywords: [String] = [],
        languageCode: String = "en-US",
        duration: TimeInterval = 60,
        context: ModelContext
    ) throws -> Note {
        let note = Note(
            transcript: transcript,
            keywords: keywords,
            duration: duration,
            languageCode: languageCode
        )
        context.insert(note)
        try context.save()
        return note
    }

    // MARK: - テスト

    /// Given 3 件のノートが存在する When filteredNotes を取得する Then 3 件が返される
    @Test("全ノートが返される（フィルタなし）")
    func returnsAllNotesWithoutFilter() throws {
        let (sut, context) = try makeViewModel()
        try insertNote(transcript: "Meeting about project", context: context)
        try insertNote(transcript: "Grocery shopping list", context: context)
        try insertNote(transcript: "Book recommendations", context: context)

        #expect(sut.filteredNotes.count == 3)
    }

    /// Given "project" で検索 When filteredNotes を取得 Then 該当ノートのみ返される
    @Test("searchText でノートをフィルタする")
    func filtersNotesBySearchText() throws {
        let (sut, context) = try makeViewModel()
        try insertNote(transcript: "Meeting about project deadline", context: context)
        try insertNote(transcript: "Grocery shopping list", context: context)

        sut.searchText = "project"
        let filtered = sut.filteredNotes

        #expect(filtered.count == 1)
        #expect(filtered.first?.transcript.contains("project") == true)
    }

    /// Given "ja-JP" でフィルタ When filteredNotes Then 日本語ノートのみ返される
    @Test("languageFilter で言語フィルタリングする")
    func filtersByLanguage() throws {
        let (sut, context) = try makeViewModel()
        try insertNote(transcript: "English note", languageCode: "en-US", context: context)
        try insertNote(transcript: "日本語のメモ", languageCode: "ja-JP", context: context)

        sut.languageFilter = "ja-JP"
        let filtered = sut.filteredNotes

        #expect(filtered.count == 1)
        #expect(filtered.first?.languageCode == "ja-JP")
    }

    /// Given ノートを削除 When deleteNotes を呼ぶ Then filteredNotes から除外される
    @Test("deleteNotes でノートが削除される")
    func deletesNote() throws {
        let (sut, context) = try makeViewModel()
        let note = try insertNote(transcript: "Delete me", context: context)

        let sectionDate = note.sectionDate
        sut.deleteNotes(at: IndexSet([0]), in: sectionDate)

        #expect(sut.filteredNotes.isEmpty)
    }

    /// Given clearFilters 呼び出し When フィルタ後にクリア Then 全ノートが返される
    @Test("clearFilters で全フィルタがリセットされる")
    func clearFiltersResetsAll() throws {
        let (sut, context) = try makeViewModel()
        try insertNote(transcript: "English note", languageCode: "en-US", context: context)
        try insertNote(transcript: "日本語のメモ", languageCode: "ja-JP", context: context)

        sut.searchText = "English"
        sut.languageFilter = "en-US"
        #expect(sut.filteredNotes.count == 1)

        sut.clearFilters()
        #expect(sut.filteredNotes.count == 2)
    }
}
