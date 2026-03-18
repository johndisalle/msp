import SwiftUI
import SwiftData

@main
struct AbideJourneyWatchApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                UserProfile.self,
                Journey.self,
                JourneyDay.self,
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
            WatchHomeView()
                .modelContainer(modelContainer)
        }
    }
}
