// NoteChain/Features/NotesList/NoteRowView.swift
// ノート一覧の行コンポーネント

import SwiftUI

/// ノート一覧の1行を表示するコンポーネント。
/// タイトル・キーワードバッジ・相対時刻・録音時間を表示する。
struct NoteRowView: View {

    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // タイトル（transcript 先頭 50 文字）
            Text(note.displayTitle)
                .font(.headline)
                .lineLimit(2)
                .foregroundStyle(.primary)

            // キーワードバッジ（上位 3 件）
            if !note.topKeywords.isEmpty {
                KeywordBadgesRow(
                    keywords: Array(note.topKeywords.prefix(3)),
                    confidences: note.keywordConfidences
                )
            }

            // メタ情報（時刻 + 録音時間）
            HStack {
                Text(note.createdAt.noteRowFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "waveform")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text(note.formattedDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            Text("\(note.displayTitle), \(note.createdAt.noteRowFormatted), \(note.formattedDuration)")
        )
    }
}

#Preview {
    List {
        NoteRowView(note: Note(
            transcript: "Had a meeting with the marketing team about Q2 planning.",
            keywords: ["meeting", "marketing", "Q2planning"],
            keywordConfidences: ["meeting": 0.9, "marketing": 0.8, "Q2planning": 0.7],
            duration: 165
        ))
        NoteRowView(note: Note(
            transcript: "マーケティングチームとのミーティングでQ2計画について話し合った。",
            keywords: ["マーケティング", "ミーティング", "計画"],
            keywordConfidences: [:],
            duration: 92,
            languageCode: "ja-JP"
        ))
    }
}
