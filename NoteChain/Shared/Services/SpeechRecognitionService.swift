// NoteChain/Shared/Services/SpeechRecognitionService.swift
// SpeechAnalyzer (iOS 26+) / SFSpeechRecognizer (iOS 17-25) の抽象化レイヤー

import AVFoundation
import Foundation
import Speech

// MARK: - TranscriptionResult

/// 音声認識の各結果を表す Sendable 値型。
/// isFinal が false = volatile（薄紫表示）、true = final（黒表示）
struct TranscriptionResult: Sendable, Equatable {
    let text: String
    let isFinal: Bool
    let confidence: Double?
    let timestamp: Date

    init(text: String, isFinal: Bool, confidence: Double? = nil) {
        self.text = text
        self.isFinal = isFinal
        self.confidence = confidence
        self.timestamp = Date()
    }
}

// MARK: - SpeechRecognitionServiceProtocol

/// 音声認識サービスの共通インターフェース。
/// SpeechAnalyzerService（iOS 26+）と LegacySpeechService（iOS 17-25）が準拠する。
protocol SpeechRecognitionServiceProtocol: Sendable {

    /// 音声認識を開始し、TranscriptionResult を AsyncThrowingStream で配信する。
    /// - Parameter locale: 認識対象の言語ロケール
    func startRecognition(locale: Locale) -> AsyncThrowingStream<TranscriptionResult, Error>

    /// 音声認識を停止し、残りのテキストを flush してストリームを終了させる。
    func stopRecognition() async

    /// このデバイス・OS で利用可能かどうか（権限状態は含まない）。
    var isAvailable: Bool { get async }
}

// MARK: - SpeechAnalyzerService (iOS 26+)

/// iOS 26+ の SpeechAnalyzer API を使った音声認識実装。
/// 完全オンデバイス・長時間音声対応・AsyncSequence ネイティブ。
@available(iOS 26, *)
final class SpeechAnalyzerService: SpeechRecognitionServiceProtocol {

    private var analyzer: SpeechAnalyzer?
    private var transcriber: SpeechTranscriber?

    func startRecognition(locale: Locale) -> AsyncThrowingStream<TranscriptionResult, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let transcriber = SpeechTranscriber(
                        locale: locale,
                        transcriptionOptions: SpeechTranscriber.Options(
                            reportPartialResults: true
                        )
                    )
                    self.transcriber = transcriber

                    let analyzer = SpeechAnalyzer(modules: [transcriber])
                    self.analyzer = analyzer

                    try await analyzer.start()

                    for try await result in transcriber.results {
                        guard !Task.isCancelled else { break }
                        let text = result.segments.map { $0.substring }.joined(separator: " ")
                        continuation.yield(TranscriptionResult(
                            text: text,
                            isFinal: result.isFinal
                        ))
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func stopRecognition() async {
        do {
            try await analyzer?.stop()
        } catch {
            // 停止エラーは無視（すでに停止済みの場合など）
        }
    }

    var isAvailable: Bool {
        get async { true } // SpeechAnalyzer はオンデバイス前提、常時利用可能
    }
}

// MARK: - LegacySpeechService (iOS 17-25)

/// iOS 17-25 向けの SFSpeechRecognizer ベースのフォールバック実装。
/// requiresOnDeviceRecognition = true でプライバシーを保護する。
/// NSObject 継承のため @unchecked Sendable を限定的に使用。
final class LegacySpeechService: NSObject, SpeechRecognitionServiceProtocol,
                                  @unchecked Sendable {

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func startRecognition(locale: Locale) -> AsyncThrowingStream<TranscriptionResult, Error> {
        AsyncThrowingStream { continuation in
            Task { @MainActor in
                guard let recognizer = SFSpeechRecognizer(locale: locale),
                      recognizer.isAvailable else {
                    continuation.finish(throwing: AppError.speechRecognitionUnavailable)
                    return
                }

                let engine = AVAudioEngine()
                self.audioEngine = engine

                let request = SFSpeechAudioBufferRecognitionRequest()
                // CRITICAL: オンデバイス処理を強制（クラウド送信を防ぐ）
                request.requiresOnDeviceRecognition = true
                request.shouldReportPartialResults = true
                self.recognitionRequest = request

                self.recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                    if let result {
                        let confidence = Double(
                            result.bestTranscription.segments.last?.confidence ?? 0
                        )
                        continuation.yield(TranscriptionResult(
                            text: result.bestTranscription.formattedString,
                            isFinal: result.isFinal,
                            confidence: confidence
                        ))
                        if result.isFinal {
                            continuation.finish()
                        }
                    }
                    if let error {
                        continuation.finish(throwing: error)
                    }
                }

                do {
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setCategory(
                        .record,
                        mode: .measurement,
                        options: .duckOthers
                    )
                    try audioSession.setActive(
                        true,
                        options: .notifyOthersOnDeactivation
                    )

                    let inputNode = engine.inputNode
                    let recordingFormat = inputNode.outputFormat(forBus: 0)
                    inputNode.installTap(
                        onBus: 0,
                        bufferSize: 1024,
                        format: recordingFormat
                    ) { buffer, _ in
                        request.append(buffer)
                    }

                    try engine.start()
                } catch {
                    continuation.finish(
                        throwing: AppError.audioEngineFailedToStart(error.localizedDescription)
                    )
                }
            }
        }
    }

    func stopRecognition() async {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil

        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }

    var isAvailable: Bool {
        get async {
            let status = SFSpeechRecognizer.authorizationStatus()
            return status == .authorized
        }
    }
}

// MARK: - Factory

/// OS バージョンに応じて適切な実装を返すファクトリ。
enum SpeechRecognitionServiceFactory {
    static func create() -> any SpeechRecognitionServiceProtocol {
        // UIテスト時は MockSpeechService を返す
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--ui-testing") {
            let mock = MockSpeechService()
            if args.contains("--mock-speech-error") {
                mock.shouldThrowError = AppError.speechRecognitionUnavailable
            } else {
                // デフォルト: volatile → final の順で結果を返す
                mock.mockResults = [
                    TranscriptionResult(text: "UIテスト文字起こし", isFinal: false),
                    TranscriptionResult(text: "UIテスト文字起こし完了", isFinal: true)
                ]
            }
            return mock
        }
        #endif
 
        if #available(iOS 26, *) {
            return SpeechAnalyzerService()
        } else {
            return LegacySpeechService()
        }
    }
}

// MARK: - Mock（テスト用）

/// テスト用モック実装。実際の音声 API は呼ばない。
final class MockSpeechService: SpeechRecognitionServiceProtocol {

    var mockResults: [TranscriptionResult] = []
    var shouldThrowError: Error? = nil
    var stopCalled: Bool = false

    func startRecognition(locale: Locale) -> AsyncThrowingStream<TranscriptionResult, Error> {
        AsyncThrowingStream { continuation in
            Task {
                if let error = shouldThrowError {
                    continuation.finish(throwing: error)
                    return
                }
                for result in mockResults {
                    continuation.yield(result)
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                }
                continuation.finish()
            }
        }
    }

    func stopRecognition() async {
        stopCalled = true
    }

    var isAvailable: Bool {
        get async { true }
    }
}
