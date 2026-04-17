import Foundation

/// Rotating, time-aware, scripture-anchored greetings for the Today screen.
///
/// Replaces the static "Good morning, [Name]" with greetings drawn from a
/// pool of ~20 per time block. The rotation is seeded by the day of year
/// so a given user sees a consistent greeting each day (not a random one
/// every scroll) but the greeting still changes daily. Also varies by
/// time block (morning / midday / afternoon / evening / late night) and
/// by days-since-last-visit so returning users get a "welcome back"
/// variant without any extra glue in the view.
enum GreetingService {

    enum TimeBlock {
        case earlyMorning, morning, midday, afternoon, evening, lateNight

        init(hour: Int) {
            switch hour {
            case 5..<8: self = .earlyMorning
            case 8..<12: self = .morning
            case 12..<14: self = .midday
            case 14..<18: self = .afternoon
            case 18..<22: self = .evening
            default: self = .lateNight
            }
        }
    }

    /// Returns a personalized greeting given the current time and the
    /// number of days since the user's last completed day.
    ///
    /// - Parameters:
    ///   - name: the user's name (or "Friend" if unknown)
    ///   - now: injectable for testing; defaults to Date()
    ///   - daysSinceLastActivity: 0 for active users; 1+ for returning users.
    ///     When >= 2, a warm "welcome back" variant is preferred.
    static func greeting(name: String, now: Date = Date(), daysSinceLastActivity: Int = 0) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1

        // Returning-user greetings take priority over time-block greetings.
        if daysSinceLastActivity >= 2 {
            return welcomeBack(name: name, days: daysSinceLastActivity, seed: dayOfYear)
        }

        let block = TimeBlock(hour: hour)
        let options = greetings(for: block)
        // Deterministic rotation so the user sees the same greeting all day.
        let idx = dayOfYear % options.count
        return options[idx].replacingOccurrences(of: "{name}", with: name)
    }

    // MARK: - Returning-user variants (grace-forward)

    private static func welcomeBack(name: String, days: Int, seed: Int) -> String {
        let options: [String]
        if days <= 3 {
            options = [
                "Welcome back, {name}. God has been waiting.",
                "Good to see you, {name}. Let's pick up right where you left off.",
                "You're back, {name}. His mercies are new this morning.",
                "No judgment, {name}. Just grace. Let's walk.",
            ]
        } else if days <= 7 {
            options = [
                "It's been a little while, {name}. He hasn't moved an inch.",
                "Welcome home, {name}. This moment is a fresh start.",
                "{name}, the door has always been open. Come in.",
                "He meets you exactly where you are, {name}.",
            ]
        } else {
            options = [
                "{name}, you're back — that matters more than you know.",
                "Welcome back, {name}. Even Peter came back. You're in good company.",
                "{name}, there's no perfect way to start again. Just start.",
                "{name}, He's been speaking all along. Let's listen today.",
            ]
        }
        let idx = abs(seed) % options.count
        return options[idx].replacingOccurrences(of: "{name}", with: name)
    }

    // MARK: - Time-block pools

    private static func greetings(for block: TimeBlock) -> [String] {
        switch block {
        case .earlyMorning:
            return [
                "This is the day the Lord has made, {name}.",
                "His mercies are new this morning, {name}.",
                "Good morning, {name} — let's walk it together.",
                "The steadfast love of the Lord never ceases, {name}.",
                "Rise with Him, {name}. The day is a gift.",
            ]
        case .morning:
            return [
                "Good morning, {name}.",
                "Morning, {name}. What will He show you today?",
                "{name}, take a breath — He's here.",
                "Grace for this morning, {name}.",
                "Welcome to today, {name}.",
            ]
        case .midday:
            return [
                "Midday, {name}. A good time to pause.",
                "{name}, His mercies are new — including for this moment.",
                "Come to me, {name}, all who are weary.",
                "Mid-stride, {name}. He's with you.",
            ]
        case .afternoon:
            return [
                "Good afternoon, {name}.",
                "{name}, He's been with you all day.",
                "Afternoon check-in, {name}. Still here. Still with Him.",
                "Pause with Him, {name}.",
            ]
        case .evening:
            return [
                "Good evening, {name}.",
                "{name}, let's close out the day together.",
                "Evening peace to you, {name}.",
                "Rest is coming, {name}. First, a breath.",
                "{name}, the Lord gives His beloved rest.",
            ]
        case .lateNight:
            return [
                "He doesn't slumber, {name}. He's still here.",
                "{name}, the night is never dark to Him.",
                "Even now, {name}, He is with you.",
                "Late hour, {name}. Good time to draw close.",
            ]
        }
    }
}
