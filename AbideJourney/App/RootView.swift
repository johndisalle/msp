import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Query private var profiles: [UserProfile]

    var body: some View {
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
    }
}

#Preview {
    RootView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
