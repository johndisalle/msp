import SwiftUI
import SwiftData

@main
struct AbideJourneyWatchApp: App {
    let modelContainer: ModelContainer?

    init() {
        // Initialize WatchConnectivity receiver early
        _ = WatchSyncReceiver.shared

        do {
            let schema = Schema([PrayerSession.self])
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
                WatchHomeView()
                    .modelContainer(modelContainer)
            } else {
                WatchHomeView()
            }
        }
    }
}
