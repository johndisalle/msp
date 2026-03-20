import SwiftUI
import SwiftData

@main
struct AbideJourneyWatchApp: App {
    let modelContainer: ModelContainer?

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
            modelContainer = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            if let modelContainer {
                WatchHomeView()
                    .modelContainer(modelContainer)
            } else {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle.fill",
                    description: Text("Please restart the app.")
                )
            }
        }
    }
}
