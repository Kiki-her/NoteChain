// NoteChainTests/Features/Onboarding/OnboardingViewModelTests.swift
// OnboardingViewModel の Swift Testing テスト

import Foundation
import Testing
@testable import NoteChain

@MainActor
struct OnboardingViewModelTests {

    // MARK: - テスト

    /// Given 初期状態 When ViewModel 生成 Then currentPage は 0
    @Test("初期ページは 0")
    func initialPageIsZero() {
        let sut = OnboardingViewModel()
        #expect(sut.currentPage == 0)
    }

    /// Given ページ 0 When advance を呼ぶ Then ページ 1 になる
    @Test("advance でページが 1 進む")
    func advanceIncrementsPage() {
        let sut = OnboardingViewModel()
        sut.advance()
        #expect(sut.currentPage == 1)
    }

    /// Given ページ 1 When goBack を呼ぶ Then ページ 0 に戻る
    @Test("goBack でページが 1 戻る")
    func goBackDecrementsPage() {
        let sut = OnboardingViewModel()
        sut.currentPage = 1
        sut.goBack()
        #expect(sut.currentPage == 0)
    }

    /// Given ページ 0 When goBack を呼ぶ Then ページは 0 のまま
    @Test("ページ 0 で goBack を呼んでもクラッシュしない")
    func goBackAtPageZeroDoesNothing() {
        let sut = OnboardingViewModel()
        sut.goBack()
        #expect(sut.currentPage == 0)
    }

    /// Given ページ 2（最終ページ）When advance を呼ぶ Then .onboardingCompleted 通知が投げられる
    @Test("最終ページで advance すると onboardingCompleted 通知が発火する")
    func advanceOnLastPagePostsNotification() async {
        let sut = OnboardingViewModel()
        sut.currentPage = 2

        var notificationReceived = false
        let observer = NotificationCenter.default.addObserver(
            forName: .onboardingCompleted,
            object: nil,
            queue: .main
        ) { _ in
            notificationReceived = true
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        sut.advance()
        // メインキューへのディスパッチを待つ
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(notificationReceived == true)
    }

    /// Given allPermissionsGranted When microphoneGranted と speechGranted が両方 true Then true
    @Test("両権限が付与済みのとき allPermissionsGranted は true")
    func allPermissionsGrantedWhenBothGranted() {
        let sut = OnboardingViewModel()
        sut.microphoneGranted = true
        sut.speechGranted = true
        #expect(sut.allPermissionsGranted == true)
    }

    /// Given speechGranted が false When allPermissionsGranted Then false
    @Test("音声認識権限未付与のとき allPermissionsGranted は false")
    func allPermissionsNotGrantedWhenSpeechDenied() {
        let sut = OnboardingViewModel()
        sut.microphoneGranted = true
        sut.speechGranted = false
        #expect(sut.allPermissionsGranted == false)
    }
}
