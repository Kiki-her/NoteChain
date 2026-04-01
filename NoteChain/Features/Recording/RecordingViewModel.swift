// NoteChain/Features/Recording/RecordingViewModel.swift
// 録音 & 文字起こしの状態管理 ViewModel

import AVFoundation
import Foundation
import Speech
import SwiftData

/// 録音画面の状態を管理する ViewModel。
/// SpeechRecognitionService の結果を UI 用プロパティに変換し、
/// 録音完了時に Note を SwiftData に保存する。
@MainActor
@Observable
final class RecordingViewModel {

    // MARK: - 公開プロパティ（UI バインディング用）

    /// 録音中フラグ
    var isRecording: Bool = false

    /// 確定済みテキスト（黒色で表示）
    var finalTranscript: String = ""

    /// 暫定テキスト（薄紫色で表示）
    var volatileTranscript: String = ""

    /// 録音経過時間（秒）
    var recordingDuration: TimeInterval = 0

    /// マイク権限拒否フラグ
    var microphonePermissionDenied: Bool = false

    /// 音声認識権限拒否フラグ
    var speechPermissionDenied: Bool = false

    /// 保存処理中フラグ（LoadingOverlay 表示用）
    var isSaving: Bool = false

    /// エラーメッセージ（nil = エラーなし）
    var errorMessage: String? = nil

    /// Note 保存完了フラグ（親 View からの遷移トリガー）
    var didSaveNote: Bool = false

    /// 保存済みの Note ID（詳細画面遷移用）
    var savedNoteID: UUID? = nil

    /// ペイウォール表示フラグ
    var showPaywall: Bool = false

    // MARK: - 依存注入

    private let speechService: any SpeechRecognitionServiceProtocol
    private let keywordExtractor: any KeywordExtractorProtocol
    private let modelContext: ModelContext

    // MARK: - 内部状態

    private var recognitionTask: Task<Void, Never>?
    private var durationTask: Task<Void, Never>?
    private var recordingStartTime: Date?

    // MARK: - イニシャライザ

    init(
        speechService: any SpeechRecognitionServiceProtocol = SpeechRecognitionServiceFactory.create(),
        keywordExtractor: any KeywordExtractorProtocol = KeywordExtractorFactory.create(),
        modelContext: ModelContext
    ) {
        self.speechService = speechService
        self.keywordExtractor = keywordExtractor
        self.modelContext = modelContext
    }

    // MARK: - 公開メソッド

    /// マイク・音声認識の権限をチェックし、必要に応じてリクエストする。
    func checkPermissions() async {
        // マイク権限チェック
        let micStatus = AVAudioApplication.shared.recordPermission
        switch micStatus {
        case .denied:
            microphonePermissionDenied = true
        case .undetermined:
            let granted = await AVAudioApplication.requestRecordPermission()
            microphonePermissionDenied = !granted
        case .granted:
            microphonePermissionDenied = false
        @unknown default:
            break
        }

        // 音声認識権限チェック
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        switch speechStatus {
        case .denied, .restricted:
            speechPermissionDenied = true
        case .notDetermined:
            let status = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
            }
            speechPermissionDenied = (status == .denied || status == .restricted)
        case .authorized:
            speechPermissionDenied = false
        @unknown default:
            break
        }
    }

    /// 録音開始/停止をトグルする。
    func toggleRecording(locale: Locale, canCreateNote: Bool) async {
        if isRecording {
            await stopAndSave()
        } else {
            guard !microphonePermissionDenied && !speechPermissionDenied else { return }
            guard canCreateNote else {
                showPaywall = true
                return
            }
            await startRecording(locale: locale)
        }
    }

    /// エラーをクリアする。
    func clearError() {
        errorMessage = nil
    }

    // MARK: - 内部メソッド

    private func startRecording(locale: Locale) async {
        isRecording = true
        finalTranscript = ""
        volatileTranscript = ""
        recordingDuration = 0
        recordingStartTime = Date()
        startDurationTimer()

        recognitionTask = Task {
            do {
                for try await result in speechService.startRecognition(locale: locale) {
                    guard !Task.isCancelled else { break }
                    if result.isFinal {
                        finalTranscript += (finalTranscript.isEmpty ? "" : " ") + result.text
                        volatileTranscript = ""
                    } else {
                        volatileTranscript = result.text
                    }
                }
            } catch is CancellationError {
                // 正常キャンセル
            } catch {
                errorMessage = AppError.recognitionTaskFailed(error.localizedDescription)
                    .errorDescription
                isRecording = false
            }
        }
    }

    private func stopAndSave() async {
        recognitionTask?.cancel()
        recognitionTask = nil
        durationTask?.cancel()
        durationTask = nil
        isRecording = false

        // 最終テキストを確定
        let fullTranscript = finalTranscript + (volatileTranscript.isEmpty ? "" : " " + volatileTranscript)
        volatileTranscript = ""

        await speechService.stopRecognition()

        guard !fullTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            // キーワード抽出（バックグラウンド）
            let extracted = await keywordExtractor.extractAsync(
                from: fullTranscript,
                maxKeywords: 5
            )
            let keywords = extracted.map { $0.keyword }
            let confidences = Dictionary(uniqueKeysWithValues: extracted.map { ($0.keyword, $0.confidence) })

            // SwiftData に保存
            let note = Note(
                transcript: fullTranscript,
                keywords: keywords,
                keywordConfidences: confidences,
                duration: recordingDuration,
                languageCode: Locale.current.identifier
            )
            modelContext.insert(note)
            try modelContext.save()

            savedNoteID = note.id
            didSaveNote = true
        } catch {
            errorMessage = AppError.swiftDataSaveFailed(error.localizedDescription).errorDescription
        }
    }

    private func startDurationTimer() {
        durationTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if isRecording {
                    recordingDuration += 1
                }
            }
        }
    }

    deinit {
        recognitionTask?.cancel()
        durationTask?.cancel()
    }
}
