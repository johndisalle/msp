import SwiftUI
import SwiftData

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable {
    case system
    case light
    case dark

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@main
struct AbideJourneyApp: App {
    let modelContainer: ModelContainer?

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("appColorTheme") private var appColorTheme: AppColorTheme = .classic

    init() {
        // Initialize analytics
        Analytics.configure()

        do {
            let schema = Schema([
                UserProfile.self,
                Journey.self,
                JourneyDay.self,
                QuizResponse.self,
                JournalEntry.self,
                DailyCheckIn.self,
                AccountabilityPartner.self
            ])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            modelContainer = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            if let modelContainer {
                RootView()
                    .id(appColorTheme)
                    .modelContainer(modelContainer)
                    .preferredColorScheme(appearanceMode.colorScheme)
                    .onOpenURL { url in
                        DeepLinkService.shared.handleURL(url)
                    }
                    .task {
                        await restorePremiumStatusIfNeeded(container: modelContainer)
                    }
            } else {
                DatabaseErrorView()
            }
        }
    }

    /// Checks StoreKit entitlements on launch and syncs premium status with the user profile.
    /// Handles the case where a user reinstalls the app or premium state was lost locally.
    @MainActor
    private func restorePremiumStatusIfNeeded(container: ModelContainer) async {
        let store = StoreKitService.shared
        await store.updatePurchasedProducts()

        let context = container.mainContext
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = try? context.fetch(descriptor).first else { return }

        if store.isPremium && !profile.isPremium {
            profile.isPremium = true
            try? context.save()
        } else if !store.isPremium && profile.isPremium {
            profile.isPremium = false
            try? context.save()
        }
    }
}

/// Shown when SwiftData fails to initialize — avoids a crash.
private struct DatabaseErrorView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Unable to Load Data", systemImage: "exclamationmark.triangle.fill")
        } description: {
            Text("Abide Journey could not open its database. Please restart the app. If the problem persists, try reinstalling.")
        }
    }
}
