import Foundation
import TelemetryDeck

/// Lightweight analytics wrapper using TelemetryDeck.
/// TelemetryDeck is privacy-first: no personal data is collected, no user consent required.
/// Dashboard: https://dashboard.telemetrydeck.com
enum Analytics {

    private static var isConfigured = false

    /// Call once at app launch before any signals are sent.
    static func configure() {
        guard let appID = Bundle.main.object(forInfoDictionaryKey: "TELEMETRYDECK_APP_ID") as? String,
              !appID.isEmpty,
              appID != "YOUR_TELEMETRYDECK_APP_ID" else {
            #if DEBUG
            print("[Analytics] TelemetryDeck not configured — using debug logging only")
            #endif
            return
        }
        let config = TelemetryDeck.Config(appID: appID)
        TelemetryDeck.initialize(config: config)
        isConfigured = true
    }

    private static func signal(_ name: String, parameters: [String: String] = [:]) {
        #if DEBUG
        if parameters.isEmpty {
            print("[Analytics] \(name)")
        } else {
            print("[Analytics] \(name) \(parameters)")
        }
        #endif
        guard isConfigured else { return }
        TelemetryDeck.signal(name, parameters: parameters)
    }

    // MARK: - Onboarding

    static func onboardingStarted() {
        signal("onboardingStarted")
    }

    static func onboardingCompleted(maturity: String) {
        signal("onboardingCompleted", parameters: ["maturity": maturity])
    }

    // MARK: - Journey Lifecycle

    static func journeyStarted(theme: String, isCouple: Bool) {
        signal("journeyStarted", parameters: [
            "theme": theme,
            "isCouple": String(isCouple)
        ])
    }

    static func journeyDayCompleted(dayNumber: Int) {
        signal("journeyDayCompleted", parameters: ["dayNumber": String(dayNumber)])
    }

    static func journeyCompleted(theme: String) {
        signal("journeyCompleted", parameters: ["theme": theme])
    }

    // MARK: - Daily Engagement

    static func prayerCompleted() {
        signal("prayerCompleted")
    }

    static func checkInSubmitted(rating: String) {
        signal("checkInSubmitted", parameters: ["rating": rating])
    }

    static func journalEntryCreated(isVoice: Bool, mood: String?) {
        var params: [String: String] = ["isVoice": String(isVoice)]
        if let mood { params["mood"] = mood }
        signal("journalEntryCreated", parameters: params)
    }

    static func actionStepCompleted() {
        signal("actionStepCompleted")
    }

    // MARK: - Monetization

    static func paywallViewed() {
        signal("paywallViewed")
    }

    static func premiumPurchased(plan: String) {
        signal("premiumPurchased", parameters: ["plan": plan])
    }

    static func premiumRestored() {
        signal("premiumRestored")
    }

    // MARK: - Features

    static func couplesJourneyStarted() {
        signal("couplesJourneyStarted")
    }

    static func customJourneyCreated() {
        signal("customJourneyCreated")
    }

    static func giftJourneySent() {
        signal("giftJourneySent")
    }

    static func accountabilityPartnerAdded() {
        signal("accountabilityPartnerAdded")
    }

    // MARK: - Milestones

    static func streakMilestone(days: Int) {
        signal("streakMilestone", parameters: ["days": String(days)])
    }
}
