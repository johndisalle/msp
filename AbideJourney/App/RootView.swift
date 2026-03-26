import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSeenWelcomeGuide") private var hasSeenWelcomeGuide = false
    @Query private var profiles: [UserProfile]
    @State private var showSplash = true
    @State private var showWelcomeGuide = false

    var body: some View {
        ZStack {
            if hasCompletedOnboarding && !profiles.isEmpty {
                MainTabView()
                    .sheet(isPresented: $showWelcomeGuide) {
                        WelcomeGuideView {
                            hasSeenWelcomeGuide = true
                            showWelcomeGuide = false
                        }
                    }
                    .onAppear {
                        if !hasSeenWelcomeGuide {
                            showWelcomeGuide = true
                        }
                    }
            } else {
                OnboardingFlowView()
                    .onAppear {
                        if hasCompletedOnboarding && profiles.isEmpty {
                            hasCompletedOnboarding = false
                        }
                    }
            }

            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showSplash = false
                }
            }
        }
        .task {
            await AuthService.shared.checkCredentialState()
        }
    }
}

// MARK: - Splash View

struct SplashView: View {
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            AJTheme.splashGradient
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white.opacity(0.9))

                VStack(spacing: 6) {
                    Text("Abide Journey")
                        .font(.system(.title2, design: .serif, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Abide in Him.")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1
            }
        }
    }
}

// MARK: - Welcome Guide

struct WelcomeGuideView: View {
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: AJTheme.paddingLarge) {
                Spacer()

                Image(systemName: "book.closed.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AJTheme.sage)

                Text("Welcome to Abide Journey")
                    .font(AJTheme.headlineFont)
                    .foregroundColor(AJTheme.primaryText)

                Text("Your personalized 40-day walk with God. Each day includes Scripture, a short devotional, action steps, and a reflection prompt — designed just for you.")
                    .font(AJTheme.bodyFont)
                    .foregroundStyle(AJTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, AJTheme.paddingLarge)

                VStack(alignment: .leading, spacing: 16) {
                    guideRow(icon: "sunrise.fill", color: AJTheme.gold,
                             text: "Open the Today tab each day for your devotional")
                    guideRow(icon: "checkmark.circle.fill", color: AJTheme.success,
                             text: "Complete action steps to build daily habits")
                    guideRow(icon: "book.fill", color: AJTheme.sage,
                             text: "Journal your reflections to track your growth")
                    guideRow(icon: "chart.bar.fill", color: AJTheme.sandstone,
                             text: "Check Progress to see how far you've come")
                }
                .padding(.horizontal, AJTheme.paddingXLarge)

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Text("Let's Begin")
                }
                .buttonStyle(AJPrimaryButtonStyle())
                .padding(.horizontal, AJTheme.paddingXLarge)
                .padding(.bottom, AJTheme.paddingXLarge)
            }
            .background(AJTheme.background.ignoresSafeArea())
            .interactiveDismissDisabled()
        }
    }

    private func guideRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
            }
            Text(text)
                .font(.system(.subheadline, design: .serif))
                .foregroundColor(AJTheme.primaryText)
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
