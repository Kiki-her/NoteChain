// NoteChain/Features/Onboarding/OnboardingView.swift
// オンボーディング画面（3ステップ PageStyle TabView）

import SwiftUI

/// アプリ初回起動時に fullScreenCover で表示されるオンボーディング画面。
/// 3ステップのスライドで NoteChain の主要機能を紹介し、権限リクエストを行う。
struct OnboardingView: View {

    @Environment(OnboardingViewModel.self) private var viewModel

    var body: some View {
        TabView(selection: Bindable(viewModel).currentPage) {
            OnboardingPageView(
                systemImage: "mic.circle.fill",
                titleKey: "onboarding_page1_title",
                descriptionKey: "onboarding_page1_description",
                tintColor: .purple
            )
            .tag(0)

            OnboardingPageView(
                systemImage: "text.magnifyingglass",
                titleKey: "onboarding_page2_title",
                descriptionKey: "onboarding_page2_description",
                tintColor: .blue
            )
            .tag(1)

            OnboardingPageView(
                systemImage: "lock.shield.fill",
                titleKey: "onboarding_page3_title",
                descriptionKey: "onboarding_page3_description",
                tintColor: .green
            )
            .tag(2)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .overlay(alignment: .bottom) {
            onboardingFooter
        }
        .task {
            await viewModel.requestPermissions()
        }
    }

    // MARK: - フッターボタン

    @ViewBuilder
    private var onboardingFooter: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.advance()
            } label: {
                Text(viewModel.currentPage < 2
                     ? LocalizedStringKey("onboarding_next")
                     : LocalizedStringKey("onboarding_get_started"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.purple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)

            if viewModel.currentPage > 0 {
                Button {
                    viewModel.goBack()
                } label: {
                    Text(LocalizedStringKey("onboarding_back"))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.bottom, 40)
    }
}

// MARK: - OnboardingPageView

/// 各オンボーディングページのレイアウト（再利用可能）。
private struct OnboardingPageView: View {

    let systemImage: String
    let titleKey: LocalizedStringKey
    let descriptionKey: LocalizedStringKey
    let tintColor: Color

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: systemImage)
                .font(.system(size: 80))
                .foregroundStyle(tintColor)
                .symbolEffect(.bounce, value: systemImage)

            VStack(spacing: 12) {
                Text(titleKey)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text(descriptionKey)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environment(OnboardingViewModel())
}
