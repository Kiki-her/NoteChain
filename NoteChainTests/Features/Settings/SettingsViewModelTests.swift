// NoteChainTests/Features/Settings/SettingsViewModelTests.swift
// SettingsViewModel の Swift Testing テスト

import Foundation
import Testing
@testable import NoteChain

@MainActor
struct SettingsViewModelTests {

    // MARK: - テスト

    /// Given recordingLanguage が "ja-JP" When speechLocale を取得 Then ja-JP Locale が返される
    @Test("recordingLanguage から正しい speechLocale が生成される")
    func speechLocaleMatchesRecordingLanguage() {
        let sut = SettingsViewModel()
        sut.recordingLanguage = "ja-JP"
        #expect(sut.speechLocale.identifier == "ja-JP")
    }

    /// Given recordingLanguage が "auto" When speechLocale を取得 Then Locale.current が返される
    @Test("auto モードでは Locale.current が返される")
    func speechLocaleIsCurrentForAuto() {
        let sut = SettingsViewModel()
        sut.recordingLanguage = "auto"
        #expect(sut.speechLocale.identifier == Locale.current.identifier)
    }

    /// Given isAutoDetectLanguage When recordingLanguage が "auto" Then true
    @Test("isAutoDetectLanguage が auto のとき true")
    func isAutoDetectLanguageReturnsTrueForAuto() {
        let sut = SettingsViewModel()
        sut.recordingLanguage = "auto"
        #expect(sut.isAutoDetectLanguage == true)
    }

    /// Given isAutoDetectLanguage When recordingLanguage が "en-US" Then false
    @Test("isAutoDetectLanguage が en-US のとき false")
    func isAutoDetectLanguageReturnsFalseForSpecificLocale() {
        let sut = SettingsViewModel()
        sut.recordingLanguage = "en-US"
        #expect(sut.isAutoDetectLanguage == false)
    }

    /// Given supportedRecordingLanguages When 件数を確認 Then 4件（auto + 3言語）
    @Test("supportedRecordingLanguages が 4 件含まれる")
    func supportedRecordingLanguagesContainsFourEntries() {
        #expect(SettingsViewModel.supportedRecordingLanguages.count == 4)
        let codes = SettingsViewModel.supportedRecordingLanguages.map { $0.code }
        #expect(codes.contains("auto"))
        #expect(codes.contains("en-US"))
        #expect(codes.contains("ja-JP"))
        #expect(codes.contains("es-ES"))
    }

    /// Given weeklyNoteCount が 2 When incrementWeeklyNoteCount Then 3 になる
    @Test("incrementWeeklyNoteCount でカウントが増える")
    func incrementWeeklyNoteCountIncrementsCount() {
        let sut = SettingsViewModel()
        sut.weeklyNoteCount = 2
        sut.incrementWeeklyNoteCount()
        #expect(sut.weeklyNoteCount == 3)
    }
}
