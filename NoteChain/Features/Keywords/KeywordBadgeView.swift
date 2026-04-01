// NoteChain/Features/Keywords/KeywordBadgeView.swift
// キーワードバッジ表示コンポーネント

import SwiftUI

/// キーワードをカプセル形バッジとして表示する再利用可能コンポーネント。
/// - タップでキーワードフィルタを発火（onTap コールバック）
/// - 削除ボタン付きモード（isEditable = true）
struct KeywordBadgeView: View {

    let keyword: String
    var confidence: Double? = nil
    var isEditable: Bool = false
    var onTap: ((String) -> Void)? = nil
    var onDelete: ((String) -> Void)? = nil

    var body: some View {
        HStack(spacing: 4) {
            Text("#\(keyword)")
                .font(.caption.bold())
                .foregroundStyle(.purple)
                .lineLimit(1)

            if isEditable {
                Button {
                    onDelete?(keyword)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.purple.opacity(0.7))
                }
                .accessibilityLabel(Text("delete_keyword \(keyword)"))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.purple.opacity(0.1), in: Capsule())
        .overlay(Capsule().stroke(.purple.opacity(0.2), lineWidth: 0.5))
        .contentShape(Capsule())
        .onTapGesture {
            if !isEditable {
                onTap?(keyword)
            }
        }
        .accessibilityLabel(Text("keyword_badge \(keyword)"))
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - KeywordBadgesRow

/// キーワードのリストを横スクロールで表示するコンポーネント。
struct KeywordBadgesRow: View {

    let keywords: [String]
    let confidences: [String: Double]
    var isEditable: Bool = false
    var onTap: ((String) -> Void)? = nil
    var onDelete: ((String) -> Void)? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(keywords, id: \.self) { keyword in
                    KeywordBadgeView(
                        keyword: keyword,
                        confidence: confidences[keyword],
                        isEditable: isEditable,
                        onTap: onTap,
                        onDelete: onDelete
                    )
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

// MARK: - Preview

#Preview("KeywordBadgeView") {
    VStack(spacing: 16) {
        // 通常バッジ
        KeywordBadgesRow(
            keywords: ["meeting", "marketing", "Q2planning"],
            confidences: ["meeting": 0.9, "marketing": 0.8, "Q2planning": 0.7]
        )

        // 編集可能バッジ
        KeywordBadgesRow(
            keywords: ["project", "deadline", "team"],
            confidences: [:],
            isEditable: true,
            onDelete: { _ in }
        )
    }
    .padding()
}
