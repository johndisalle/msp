import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if hasCompletedOnboarding, profiles.first != nil {
                MainTabView()
            } else {
                OnboardingFlowView()
            }
        }
        .animation(.easeInOut, value: hasCompletedOnboarding)
    }
}

#Preview {
    RootView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
