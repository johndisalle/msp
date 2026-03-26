import SwiftUI

@main
struct AbideJourneyWatchApp: App {
    init() {
        // Initialize WatchConnectivity receiver early
        _ = WatchSyncReceiver.shared
    }

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
    }
}
