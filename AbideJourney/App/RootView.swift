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
                        // AppStorage says done but SwiftData has no profile —
                        // clear the flag so onboarding runs to completion cleanly.
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
            // Brief branded splash, then fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Splash View

struct SplashView: View {
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.accentColor
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("\u{2720}")
                    .font(.system(size: 64, weight: .thin))
                    .foregroundStyle(.white)

                Text("Abide in Him.")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(.white.opacity(0.85))
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
            VStack(spacing: 24) {
                Spacer()

                Text("\u{2720}")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundStyle(.accent)

                Text("Welcome to Abide Journey")
                    .font(.title2.bold())

                Text("Your personalized 40-day walk with God. Each day includes Scripture, a short devotional, action steps, and a reflection prompt — designed just for you.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 16) {
                    guideRow(icon: "sun.max.fill", color: .orange,
                             text: "Open the Today tab each day for your devotional")
                    guideRow(icon: "checkmark.circle.fill", color: .green,
                             text: "Complete action steps to build daily habits")
                    guideRow(icon: "book.fill", color: .blue,
                             text: "Journal your reflections to track your growth")
                    guideRow(icon: "chart.bar.fill", color: .purple,
                             text: "Check Progress to see how far you've come")
                }
                .padding(.horizontal, 32)

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Text("Let's Begin")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .interactiveDismissDisabled()
        }
    }

    private func guideRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
