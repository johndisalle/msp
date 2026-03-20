import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Query private var profiles: [UserProfile]
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if hasCompletedOnboarding && !profiles.isEmpty {
                MainTabView()
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

#Preview {
    RootView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
