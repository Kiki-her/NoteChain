// NoteChainTests/Features/Recording/RecordingViewModelTests.swift
// RecordingViewModel の Swift Testing テスト

import Foundation
import SwiftData
import Testing
@testable import NoteChain

@MainActor
struct RecordingViewModelTests {

    // MARK: - テスト用ヘルパー

    private func makeViewModel(
        speechService: MockSpeechService = MockSpeechService(),
        keywordExtractor: MockKeywordExtractor = MockKeywordExtractor()
    ) throws -> RecordingViewModel {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Note.self, configurations: config)
        return RecordingViewModel(
            speechService: speechService,
            keywordExtractor: keywordExtractor,
            modelContext: container.mainContext
        )
    }

    // MARK: - テスト

    /// Given 初期状態 When ViewModel が生成される Then isRecording は false
    @Test("初期状態で isRecording は false")
    func initialStateIsNotRecording() throws {
        let sut = try makeViewModel()
        #expect(sut.isRecording == false)
        #expect(sut.finalTranscript == "")
        #expect(sut.volatileTranscript == "")
    }

    /// Given モックが volatile → final の順で結果を返す
    /// When toggleRecording を呼ぶ
    /// Then finalTranscript に最終テキストが入る
    @Test("volatile → final の順で finalTranscript が更新される")
    func transcriptUpdatesFromVolatileToFinal() async throws {
        let mockService = MockSpeechService()
        mockService.mockResults = [
            TranscriptionResult(text: "Hello", isFinal: false),
            TranscriptionResult(text: "Hello world", isFinal: true)
        ]
        let sut = try makeViewModel(speechService: mockService)

        // 権限フラグを強制的に許可状態にする
        sut.microphonePermissionDenied = false
        sut.speechPermissionDenied = false

        // 録音を開始
        await sut.toggleRecording(locale: Locale(identifier: "en-US"), canCreateNote: true)

        // 少し待って非同期処理を完了させる
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(sut.finalTranscript.contains("Hello world"))
    }

    /// Given canCreateNote が false
    /// When toggleRecording を呼ぶ
    /// Then showPaywall が true になる
    @Test("canCreateNote false でペイウォールが表示される")
    func paywallShownWhenCannotCreateNote() async throws {
        let sut = try makeViewModel()
        await sut.toggleRecording(locale: Locale(identifier: "en-US"), canCreateNote: false)
        #expect(sut.showPaywall == true)
        #expect(sut.isRecording == false)
    }

    /// Given モックサービスがエラーをスローする
    /// When 録音開始 Then errorMessage が設定される
    @Test("音声認識エラー時に errorMessage が設定される")
    func errorMessageSetOnRecognitionFailure() async throws {
        let mockService = MockSpeechService()
        mockService.shouldThrowError = AppError.speechRecognitionUnavailable
        let sut = try makeViewModel(speechService: mockService)

        // 権限フラグを強制的に許可状態にする
        sut.microphonePermissionDenied = false
        sut.speechPermissionDenied = false

        await sut.toggleRecording(locale: Locale(identifier: "en-US"), canCreateNote: true)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.errorMessage != nil)
    }
}
