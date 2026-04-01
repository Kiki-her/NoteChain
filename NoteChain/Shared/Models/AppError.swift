// NoteChain/Shared/Models/AppError.swift
// アプリ共通エラー型 — LocalizedError 準拠、全モジュールで使用

import Foundation

/// NoteChain アプリ全体で使用する共通エラー型。
/// LocalizedError 準拠でユーザー向けメッセージを提供する。
enum AppError: LocalizedError, Equatable {

    // MARK: - 音声認識エラー
    case microphonePermissionDenied
    case speechRecognitionPermissionDenied
    case speechRecognitionUnavailable
    case audioEngineFailedToStart(String)
    case audioSessionInterrupted
    case recognitionTaskFailed(String)

    // MARK: - データエラー
    case noteNotFound(UUID)
    case swiftDataSaveFailed(String)
    case swiftDataFetchFailed(String)
    case noteDeleteFailed(String)

    // MARK: - キーワード抽出エラー
    case keywordExtractionFailed(String)
    case emptyTranscriptForExtraction

    // MARK: - サブスクリプションエラー
    case productFetchFailed(String)
    case purchaseFailed(String)
    case restorePurchaseFailed(String)
    case weeklyLimitReached

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return String(localized: "error_microphone_denied")
        case .speechRecognitionPermissionDenied:
            return String(localized: "error_speech_permission_denied")
        case .speechRecognitionUnavailable:
            return String(localized: "error_speech_unavailable")
        case .audioEngineFailedToStart(let detail):
            return "\(String(localized: "error_audio_engine")): \(detail)"
        case .audioSessionInterrupted:
            return String(localized: "error_audio_interrupted")
        case .recognitionTaskFailed(let detail):
            return "\(String(localized: "error_recognition_failed")): \(detail)"
        case .noteNotFound(let id):
            return "\(String(localized: "error_note_not_found")): \(id)"
        case .swiftDataSaveFailed(let detail):
            return "\(String(localized: "error_save_failed")): \(detail)"
        case .swiftDataFetchFailed(let detail):
            return "\(String(localized: "error_fetch_failed")): \(detail)"
        case .noteDeleteFailed(let detail):
            return "\(String(localized: "error_delete_failed")): \(detail)"
        case .keywordExtractionFailed(let reason):
            return "\(String(localized: "error_keyword_extraction")): \(reason)"
        case .emptyTranscriptForExtraction:
            return String(localized: "error_empty_transcript")
        case .productFetchFailed(let detail):
            return "\(String(localized: "error_product_fetch")): \(detail)"
        case .purchaseFailed(let detail):
            return "\(String(localized: "error_purchase")): \(detail)"
        case .restorePurchaseFailed(let detail):
            return "\(String(localized: "error_restore")): \(detail)"
        case .weeklyLimitReached:
            return String(localized: "error_weekly_limit")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .microphonePermissionDenied, .speechRecognitionPermissionDenied:
            return String(localized: "recovery_open_settings")
        case .weeklyLimitReached:
            return String(localized: "recovery_upgrade_pro")
        default:
            return String(localized: "recovery_try_again")
        }
    }

    // MARK: - Equatable
    // Associated value に Error を含まないため標準的に実装

    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.microphonePermissionDenied, .microphonePermissionDenied),
             (.speechRecognitionPermissionDenied, .speechRecognitionPermissionDenied),
             (.speechRecognitionUnavailable, .speechRecognitionUnavailable),
             (.audioSessionInterrupted, .audioSessionInterrupted),
             (.emptyTranscriptForExtraction, .emptyTranscriptForExtraction),
             (.weeklyLimitReached, .weeklyLimitReached):
            return true
        case (.noteNotFound(let a), .noteNotFound(let b)):
            return a == b
        case (.audioEngineFailedToStart(let a), .audioEngineFailedToStart(let b)),
             (.recognitionTaskFailed(let a), .recognitionTaskFailed(let b)),
             (.swiftDataSaveFailed(let a), .swiftDataSaveFailed(let b)),
             (.swiftDataFetchFailed(let a), .swiftDataFetchFailed(let b)),
             (.noteDeleteFailed(let a), .noteDeleteFailed(let b)),
             (.keywordExtractionFailed(let a), .keywordExtractionFailed(let b)),
             (.productFetchFailed(let a), .productFetchFailed(let b)),
             (.purchaseFailed(let a), .purchaseFailed(let b)),
             (.restorePurchaseFailed(let a), .restorePurchaseFailed(let b)):
            return a == b
        default:
            return false
        }
    }
}
