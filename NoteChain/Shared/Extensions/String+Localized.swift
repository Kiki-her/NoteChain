// NoteChain/Shared/Extensions/String+Localized.swift
// ローカライズ補助拡張

import Foundation

extension Bundle {
    /// アプリのバージョン文字列（例: "1.0.0 (42)"）
    var appVersionString: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
