import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showLaunchScreen = true

    var body: some View {
        ZStack {
            Group {
                if !hasCompletedOnboarding {
                    OnboardingFlowView()
                        .transition(.move(edge: .leading).combined(with: .opacity))
                } else {
                    MainTabView()
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.5), value: hasCompletedOnboarding)

            if showLaunchScreen {
                LaunchScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showLaunchScreen = false
                }
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
}
