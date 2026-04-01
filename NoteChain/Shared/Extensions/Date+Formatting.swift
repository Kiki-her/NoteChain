// NoteChain/Shared/Extensions/Date+Formatting.swift
// 日付フォーマット・相対時刻の拡張

import Foundation

extension Date {

    /// 相対時刻文字列（"2 minutes ago", "Yesterday" など）
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// 時刻のみ表示（"14:32"）
    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// 日付セクションヘッダー用（"Today", "Yesterday", "April 1"）
    var sectionHeaderFormatted: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return String(localized: "date_today")
        } else if calendar.isDateInYesterday(self) {
            return String(localized: "date_yesterday")
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: self)
        }
    }

    /// ノート行の表示用（相対時刻 + 時刻）
    var noteRowFormatted: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return relativeFormatted
        } else {
            return timeFormatted
        }
    }
}
