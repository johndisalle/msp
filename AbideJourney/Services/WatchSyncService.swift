import Foundation
import WatchConnectivity

/// Sends current journey data to the Apple Watch via WatchConnectivity.
/// Call `sync(...)` whenever the current day loads or a day is completed.
final class WatchSyncService: NSObject, WCSessionDelegate {
    static let shared = WatchSyncService()

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Send Data to Watch

    func sync(
        dayNumber: Int,
        totalDays: Int,
        currentDay: Int,
        focusArea: String,
        scriptureReference: String,
        scriptureText: String,
        devotionalTitle: String,
        devotionalText: String,
        reflectionPrompt: String,
        journeyTitle: String,
        progress: Double,
        currentStreak: Int,
        longestStreak: Int
    ) {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated else { return }

        let context: [String: Any] = [
            "dayNumber": dayNumber,
            "totalDays": totalDays,
            "currentDay": currentDay,
            "focusArea": focusArea,
            "scriptureReference": scriptureReference,
            "scriptureText": scriptureText,
            "devotionalTitle": devotionalTitle,
            "devotionalText": devotionalText,
            "reflectionPrompt": reflectionPrompt,
            "journeyTitle": journeyTitle,
            "progress": progress,
            "currentStreak": currentStreak,
            "longestStreak": longestStreak,
            "lastUpdated": Date().timeIntervalSince1970
        ]

        try? WCSession.default.updateApplicationContext(context)
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
