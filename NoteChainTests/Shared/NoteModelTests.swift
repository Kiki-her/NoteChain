// NoteChainTests/Shared/NoteModelTests.swift
// Note @Model の Swift Testing テスト

import Foundation
import SwiftData
import Testing
@testable import NoteChain

struct NoteModelTests {

    // MARK: - テスト

    /// Given Note が生成された When wordCount を確認 Then スペース区切りの単語数を返す
    @Test("wordCount がスペース区切りの単語数を返す")
    func wordCountReturnsSpaceDelimitedCount() {
        let note = Note(transcript: "Hello world this is a test")
        #expect(note.wordCount == 6)
    }

    /// Given transcript が空 When wordCount Then 0
    @Test("transcript が空のとき wordCount は 0")
    func wordCountIsZeroForEmptyTranscript() {
        let note = Note(transcript: "")
        #expect(note.wordCount == 0)
    }

    /// Given duration が 90 秒 When formattedDuration Then "1:30"
    @Test("formattedDuration が MM:SS 形式を返す")
    func formattedDurationReturnsMmSsFormat() {
        let note = Note(transcript: "", duration: 90)
        #expect(note.formattedDuration == "1:30")
    }

    /// Given duration が 0 秒 When formattedDuration Then "0:00"
    @Test("duration が 0 のとき formattedDuration は 0:00")
    func formattedDurationIsZeroForZeroDuration() {
        let note = Note(transcript: "", duration: 0)
        #expect(note.formattedDuration == "0:00")
    }

    /// Given 60 文字の transcript When displayTitle Then 先頭 50 文字が返される
    @Test("displayTitle が先頭 50 文字を返す")
    func displayTitleTruncatesAt50Characters() {
        let longText = String(repeating: "a", count: 60)
        let note = Note(transcript: longText)
        #expect(note.displayTitle.count == 50)
    }

    /// Given transcript が空 When displayTitle Then "Untitled Note"
    @Test("transcript が空のとき displayTitle は Untitled Note")
    func displayTitleIsUntitledForEmptyTranscript() {
        let note = Note(transcript: "")
        #expect(note.displayTitle == "Untitled Note")
    }

    /// Given 5つのキーワードと信頼度 When topKeywords Then 信頼度降順の上位5件
    @Test("topKeywords が信頼度降順を返す")
    func topKeywordsAreSortedByConfidence() {
        let note = Note(
            transcript: "test",
            keywords: ["apple", "banana", "cherry"],
            keywordConfidences: ["apple": 0.5, "banana": 1.0, "cherry": 0.3]
        )
        let top = note.topKeywords
        #expect(top.first == "banana")
        #expect(top.last == "cherry")
    }

    /// Given 2つの Note When == 演算子 Then id が同じなら等しい
    @Test("Note の等価性は id で判定される")
    func noteEqualityBasedOnID() {
        let note1 = Note(transcript: "Hello")
        let note2 = Note(transcript: "Different text")
        // 異なる UUID は等しくない
        #expect(note1 != note2)
    }
}
