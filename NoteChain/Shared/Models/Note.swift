// NoteChain/Shared/Models/Note.swift
// SwiftData @Model エンティティ — NoteChain の中核データモデル

import Foundation
import SwiftData

/// NoteChain のボイスメモを表す SwiftData モデル。
/// transcript（文字起こし）・keywords（抽出キーワード）・メタデータを保持する。
@Model
final class Note {

    // MARK: - 永続化プロパティ

    /// 一意識別子（重複挿入防止）
    @Attribute(.unique) var id: UUID

    /// ローカルオーディオファイルの URL（任意）
    var audioFileURL: URL?

    /// 最終確定した文字起こしテキスト
    var transcript: String

    /// 抽出済みキーワードリスト（信頼度順に並べ替え済み）
    var keywords: [String]

    /// キーワード → 信頼度スコア（0.0–1.0）のマッピング
    var keywordConfidences: [String: Double]

    /// 作成日時（ソート・日付セクション分けに使用）
    var createdAt: Date

    /// 最終更新日時
    var updatedAt: Date

    /// 録音時間（秒）
    var duration: TimeInterval

    /// 録音言語のロケール識別子（例: "en-US", "ja-JP", "es-ES"）
    var languageCode: String

    /// お気に入りフラグ
    var isFavorite: Bool

    // MARK: - 計算プロパティ（非永続）

    /// テキストの単語数（スペース区切り）
    var wordCount: Int {
        guard !transcript.isEmpty else { return 0 }
        return transcript.split(separator: " ").count
    }

    /// "MM:SS" 形式の録音時間文字列
    var formattedDuration: String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// transcript の先頭50文字（タイトル表示用）
    var displayTitle: String {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Untitled Note" }
        return String(trimmed.prefix(50))
    }

    /// 時刻を切り捨てた日付（日付セクション分け用）
    var sectionDate: Date {
        Calendar.current.startOfDay(for: createdAt)
    }

    /// 信頼度順の上位5キーワード
    var topKeywords: [String] {
        keywords
            .sorted { (keywordConfidences[$0] ?? 0) > (keywordConfidences[$1] ?? 0) }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - イニシャライザ

    init(
        transcript: String = "",
        keywords: [String] = [],
        keywordConfidences: [String: Double] = [:],
        duration: TimeInterval = 0,
        languageCode: String = "en-US",
        audioFileURL: URL? = nil
    ) {
        self.id = UUID()
        self.transcript = transcript
        self.keywords = keywords
        self.keywordConfidences = keywordConfidences
        self.createdAt = Date()
        self.updatedAt = Date()
        self.duration = duration
        self.languageCode = languageCode
        self.audioFileURL = audioFileURL
        self.isFavorite = false
    }
}

// MARK: - Hashable

extension Note: Hashable {
    static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
