import SwiftUI
import SwiftData

@main
struct AbideJourneyApp: App {
    let modelContainer: ModelContainer?

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        do {
            let schema = Schema([
                UserProfile.self,
                Journey.self,
                JourneyDay.self,
                QuizResponse.self,
                JournalEntry.self,
                DailyCheckIn.self,
                PrayerSession.self,
                AccountabilityPartner.self
            ])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
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
                    .modelContainer(modelContainer)
            } else {
                DatabaseErrorView()
            }
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
