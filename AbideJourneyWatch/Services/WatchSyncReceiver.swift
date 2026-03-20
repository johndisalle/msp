import Foundation
import WatchConnectivity

/// Receives journey data from the iPhone via WatchConnectivity.
/// Publishes updates so Watch views can observe changes.
@Observable
final class WatchSyncReceiver: NSObject, WCSessionDelegate {
    static let shared = WatchSyncReceiver()

    // Current journey state synced from iPhone
    var dayNumber: Int = 0
    var totalDays: Int = 40
    var currentDay: Int = 0
    var focusArea: String = ""
    var scriptureReference: String = ""
    var scriptureText: String = ""
    var devotionalTitle: String = ""
    var devotionalText: String = ""
    var reflectionPrompt: String = ""
    var journeyTitle: String = ""
    var progress: Double = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var hasData: Bool = false

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
        // Load any previously received context
        applyContext(WCSession.default.receivedApplicationContext)
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            DispatchQueue.main.async {
                self.applyContext(session.receivedApplicationContext)
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            self.applyContext(applicationContext)
        }
    }

    // MARK: - Apply Context

    private func applyContext(_ context: [String: Any]) {
        guard !context.isEmpty else { return }

        dayNumber = context["dayNumber"] as? Int ?? 0
        totalDays = context["totalDays"] as? Int ?? 40
        currentDay = context["currentDay"] as? Int ?? 0
        focusArea = context["focusArea"] as? String ?? ""
        scriptureReference = context["scriptureReference"] as? String ?? ""
        scriptureText = context["scriptureText"] as? String ?? ""
        devotionalTitle = context["devotionalTitle"] as? String ?? ""
        devotionalText = context["devotionalText"] as? String ?? ""
        reflectionPrompt = context["reflectionPrompt"] as? String ?? ""
        journeyTitle = context["journeyTitle"] as? String ?? ""
        progress = context["progress"] as? Double ?? 0
        currentStreak = context["currentStreak"] as? Int ?? 0
        longestStreak = context["longestStreak"] as? Int ?? 0
        hasData = dayNumber > 0
    }
}
