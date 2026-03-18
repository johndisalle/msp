import SwiftUI
import SwiftData

@main
struct AbideJourneyApp: App {
    let modelContainer: ModelContainer

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
                PrayerSession.self
            ])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(modelContainer)
        }
    }
}
