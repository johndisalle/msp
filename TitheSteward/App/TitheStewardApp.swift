import SwiftUI
import SwiftData

@main
struct TitheStewardApp: App {
    @StateObject private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            TitheRecord.self,
            BudgetCategory.self,
            BudgetTransaction.self,
            DebtItem.self,
            DebtPayment.self,
            DevotionalCompletion.self,
            GivingRecipient.self,
            RecurringGift.self,
            ChatSession.self,
            GenerosityBadge.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                let context = sharedModelContainer.mainContext
                RecurringGiftScheduler.shared.processAndSchedule(modelContext: context)
            }
        }
    }
}

class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isPremium = false

    init() {
        checkAuthState()
    }

    func checkAuthState() {
        if let _ = UserDefaults.standard.string(forKey: "appleUserId") {
            isAuthenticated = true
        }
    }

    func signOut() {
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "appleUserId")
    }
}
