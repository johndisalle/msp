import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingFlowView()
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
