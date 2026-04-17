import SwiftUI
import SwiftData
import UserNotifications
import FirebaseCore

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
        FirebaseApp.configure()

        // Initialize analytics
        Analytics.configure()

        // Record install date for smart review prompts
        ReviewPromptService.shared.recordInstallDateIfNeeded()

        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared

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
                        await AuthService.shared.bootstrap()
                        await restorePremiumStatusIfNeeded(container: modelContainer)
                        await refreshNotificationSchedule(container: modelContainer)
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

        // Also check admin-granted premium (Firestore flag)
        let adminGrantedPremium = AuthService.shared.isPremiumFromGrant

        let context = container.mainContext
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = try? context.fetch(descriptor).first else { return }
        // Effective premium = StoreKit OR admin-granted.
        // Don't downgrade if either is true. Only flip to false if BOTH are false.
        let effectivePremium = store.isPremium || adminGrantedPremium
        if profile.isPremium != effectivePremium {
            profile.isPremium = effectivePremium
        }


        if store.isPremium && !profile.isPremium {
            profile.isPremium = true
            try? context.save()
        } else if !store.isPremium && profile.isPremium {
            profile.isPremium = false
            try? context.save()
        }
    }

    @MainActor
    private func refreshNotificationSchedule(container: ModelContainer) async {
        let context = container.mainContext

        let profileDescriptor = FetchDescriptor<UserProfile>()
        guard let profile = try? context.fetch(profileDescriptor).first,
              profile.notificationsEnabled else { return }

        let journeyDescriptor = FetchDescriptor<Journey>(predicate: #Predicate { $0.isActive })
        guard let journey = try? context.fetch(journeyDescriptor).first else { return }

        NotificationService.shared.scheduleRollingNotifications(profile: profile, journey: journey)

        let completedDays = (journey.days ?? []).filter { $0.isCompleted }
        let lastActivity = completedDays.compactMap { $0.date }.max() ?? journey.startDate
        let calendar = Calendar.current
        let daysSince = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: lastActivity),
            to: calendar.startOfDay(for: Date())
        ).day ?? 0

        if daysSince >= 1 {
            NotificationService.shared.scheduleComebackNotifications(
                daysSinceLastActivity: daysSince,
                morningTime: profile.notificationMorningTime
            )
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


// MARK: - Notification Delegate

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let path = userInfo["deepLinkPath"] as? String {
            let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
            if let url = URL(string: "abidejourney://\(trimmed)") {
                DispatchQueue.main.async {
                    DeepLinkService.shared.handleURL(url)
                }
            }
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
