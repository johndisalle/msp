import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingFlowView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut, value: hasCompletedOnboarding)
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
}
