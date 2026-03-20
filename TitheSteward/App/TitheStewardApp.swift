import SwiftUI

@main
struct TitheStewardApp: App {
    @StateObject private var appState = AppState()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isPremium = false
    @Published var currentUser: UserProfile?

    init() {
        // Check authentication state on launch
        checkAuthState()
    }

    func checkAuthState() {
        // Check Keychain for existing session
        if let _ = UserDefaults.standard.string(forKey: "userId") {
            isAuthenticated = true
        }
    }

    func signOut() {
        isAuthenticated = false
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: "userId")
    }
}
