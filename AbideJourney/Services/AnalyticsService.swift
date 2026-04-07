import Foundation

/// Lightweight analytics wrapper.
/// Replace the print statements with your analytics SDK (e.g. TelemetryDeck, Mixpanel)
/// when ready to ship.
enum Analytics {

    /// Call once at app launch before any signals are sent.
    static func configure() {
        // TODO: Initialize your analytics SDK here
        // e.g. TelemetryDeck.initialize(config: .init(appID: "YOUR_APP_ID"))
    }

    private static func signal(_ name: String, parameters: [String: String] = [:]) {
        #if DEBUG
        if parameters.isEmpty {
            print("[Analytics] \(name)")
        } else {
            print("[Analytics] \(name) \(parameters)")
        }
        #endif
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
