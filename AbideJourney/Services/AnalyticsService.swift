import Foundation
import TelemetryDeck

/// Lightweight analytics wrapper around TelemetryDeck.
/// All events are anonymous — no personal data is collected.
enum Analytics {

    /// Call once at app launch before any signals are sent.
    static func configure() {
        let config = TelemetryDeck.Config(appID: "YOUR_TELEMETRYDECK_APP_ID")
        TelemetryDeck.initialize(config: config)
    }

    // MARK: - Onboarding

    static func onboardingStarted() {
        TelemetryDeck.signal("onboardingStarted")
    }

    static func onboardingCompleted(maturity: String) {
        TelemetryDeck.signal("onboardingCompleted", parameters: ["maturity": maturity])
    }

    // MARK: - Journey Lifecycle

    static func journeyStarted(theme: String, isCouple: Bool) {
        TelemetryDeck.signal("journeyStarted", parameters: [
            "theme": theme,
            "isCouple": String(isCouple)
        ])
    }

    static func journeyDayCompleted(dayNumber: Int) {
        TelemetryDeck.signal("journeyDayCompleted", parameters: ["dayNumber": String(dayNumber)])
    }

    static func journeyCompleted(theme: String) {
        TelemetryDeck.signal("journeyCompleted", parameters: ["theme": theme])
    }

    // MARK: - Daily Engagement

    static func prayerCompleted() {
        TelemetryDeck.signal("prayerCompleted")
    }

    static func checkInSubmitted(rating: String) {
        TelemetryDeck.signal("checkInSubmitted", parameters: ["rating": rating])
    }

    static func journalEntryCreated(isVoice: Bool, mood: String?) {
        var params: [String: String] = ["isVoice": String(isVoice)]
        if let mood { params["mood"] = mood }
        TelemetryDeck.signal("journalEntryCreated", parameters: params)
    }

    static func actionStepCompleted() {
        TelemetryDeck.signal("actionStepCompleted")
    }

    // MARK: - Monetization

    static func paywallViewed() {
        TelemetryDeck.signal("paywallViewed")
    }

    static func premiumPurchased(plan: String) {
        TelemetryDeck.signal("premiumPurchased", parameters: ["plan": plan])
    }

    static func premiumRestored() {
        TelemetryDeck.signal("premiumRestored")
    }

    // MARK: - Features

    static func couplesJourneyStarted() {
        TelemetryDeck.signal("couplesJourneyStarted")
    }

    static func customJourneyCreated() {
        TelemetryDeck.signal("customJourneyCreated")
    }

    static func giftJourneySent() {
        TelemetryDeck.signal("giftJourneySent")
    }

    static func accountabilityPartnerAdded() {
        TelemetryDeck.signal("accountabilityPartnerAdded")
    }

    // MARK: - Milestones

    static func streakMilestone(days: Int) {
        TelemetryDeck.signal("streakMilestone", parameters: ["days": String(days)])
    }
}
