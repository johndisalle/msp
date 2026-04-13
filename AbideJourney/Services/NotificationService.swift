import Foundation
import UserNotifications
import SwiftData

final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    // MARK: - Rolling 14-day schedule

    func scheduleRollingNotifications(profile: UserProfile, journey: Journey) {
        center.removeAllPendingNotificationRequests()

        let calendar = Calendar.current
        let now = Date()
        let morningComps = calendar.dateComponents([.hour, .minute], from: profile.notificationMorningTime)
        let eveningComps = calendar.dateComponents([.hour, .minute], from: profile.notificationEveningTime)

        let totalDays = journey.totalDays
        let startDate = calendar.startOfDay(for: journey.startDate)

        let completed = Set((journey.days ?? []).filter { $0.isCompleted }.map { $0.dayNumber })
        let daysByNumber = Dictionary(uniqueKeysWithValues: (journey.days ?? []).map { ($0.dayNumber, $0) })

        for offset in 0..<14 {
            guard let targetDate = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
            let targetDay = calendar.startOfDay(for: targetDate)
            let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: targetDay).day ?? 0
            let dayNumber = daysSinceStart + 1

            guard dayNumber >= 1 && dayNumber <= totalDays else { continue }
            guard !completed.contains(dayNumber) else { continue }

            let snippet = String((daysByNumber[dayNumber]?.scriptureText ?? "Today's verse is waiting.").prefix(120))
            let morningFire = combinedDate(date: targetDay, components: morningComps, calendar: calendar)
            let eveningFire = combinedDate(date: targetDay, components: eveningComps, calendar: calendar)

            scheduleMorning(at: morningFire, dayNumber: dayNumber, verseSnippet: snippet, isPremium: profile.isPremium)
            scheduleEvening(at: eveningFire, dayNumber: dayNumber)
        }
    }

    private func combinedDate(date: Date, components: DateComponents, calendar: Calendar) -> Date {
        var combined = calendar.dateComponents([.year, .month, .day], from: date)
        combined.hour = components.hour
        combined.minute = components.minute
        return calendar.date(from: combined) ?? date
    }

    private func scheduleMorning(at fireDate: Date, dayNumber: Int, verseSnippet: String, isPremium: Bool = true) {
        guard fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Day \(dayNumber) — Your Verse Today"
        content.subtitle = "Good Morning ☀️"
        var body = "\u{201C}\(verseSnippet)\u{201D}\nTap to read today's devotional."
        var deepLinkPath = "/today"
        if dayNumber == 14 && !isPremium {
            body += " · Tap to unlock more journeys"
            deepLinkPath = "/upgrade"
        }
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "MORNING_DEVOTIONAL"
        content.userInfo = ["deepLinkPath": deepLinkPath]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: "rolling-morning-day\(dayNumber)", content: content, trigger: trigger)
        center.add(request)
    }

    private func scheduleEvening(at fireDate: Date, dayNumber: Int) {
        guard fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Evening Reflection 🌙"
        content.body = "How was Day \(dayNumber)? Take a moment to reflect and journal before the day ends."
        content.sound = .default
        content.categoryIdentifier = "EVENING_CHECKIN"
        content.userInfo = ["deepLinkPath": "/today"]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: "rolling-evening-day\(dayNumber)", content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Comeback Notifications

    func scheduleComebackNotifications(daysSinceLastActivity: Int, morningTime: Date) {
        guard daysSinceLastActivity >= 1 else { return }

        center.removePendingNotificationRequests(withIdentifiers: ["comeback-1", "comeback-3", "comeback-7"])

        let calendar = Calendar.current
        let timeComps = calendar.dateComponents([.hour, .minute], from: morningTime)

        let messages: [(daysAhead: Int, identifier: String, body: String)] = [
            (1, "comeback-1", "Your journey is right where you left off. Tap to pick up today."),
            (3, "comeback-3", "It's been a few days. Take 5 minutes — your verse is waiting."),
            (7, "comeback-7", "Even Peter denied Jesus three times. Let's restart together.")
        ]

        for msg in messages {
            guard let targetDate = calendar.date(byAdding: .day, value: msg.daysAhead, to: Date()) else { continue }
            var fireComps = calendar.dateComponents([.year, .month, .day], from: targetDate)
            fireComps.hour = timeComps.hour
            fireComps.minute = timeComps.minute

            let content = UNMutableNotificationContent()
            content.title = "We Miss You"
            content.body = msg.body
            content.sound = .default
            content.userInfo = ["deepLinkPath": "/today?source=comeback"]

            let trigger = UNCalendarNotificationTrigger(dateMatching: fireComps, repeats: false)
            let request = UNNotificationRequest(identifier: msg.identifier, content: content, trigger: trigger)
            center.add(request)
        }
    }

    // MARK: - Legacy single-day scheduling (kept for backward compatibility)

    func scheduleMorningReminder(at time: Date, dayNumber: Int, verseSnippet: String) {
        let content = UNMutableNotificationContent()
        content.title = "Day \(dayNumber) — Your Verse Today"
        content.subtitle = "Good Morning ☀️"
        content.body = "\u{201C}\(verseSnippet)\u{201D}\nTap to read today's devotional."
        content.sound = .default
        content.categoryIdentifier = "MORNING_DEVOTIONAL"
        content.userInfo = ["deepLinkPath": "/today"]

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "morning-\(dayNumber)", content: content, trigger: trigger)
        center.add(request)
    }

    func scheduleEveningCheckIn(at time: Date, dayNumber: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Evening Reflection 🌙"
        content.body = "How was Day \(dayNumber)? Take a moment to reflect and journal before the day ends."
        content.sound = .default
        content.categoryIdentifier = "EVENING_CHECKIN"
        content.userInfo = ["deepLinkPath": "/today"]

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "evening-\(dayNumber)", content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Cancel

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Notification Categories

    func registerCategories() {
        let startAction = UNNotificationAction(identifier: "START_DEVOTIONAL", title: "Start Devotional", options: .foreground)
        let prayAction = UNNotificationAction(identifier: "START_PRAYER", title: "Pray Now", options: .foreground)
        let checkInGreat = UNNotificationAction(identifier: "CHECKIN_GREAT", title: "🔥 Great")
        let checkInGood = UNNotificationAction(identifier: "CHECKIN_GOOD", title: "👍 Good")
        let checkInTough = UNNotificationAction(identifier: "CHECKIN_TOUGH", title: "😓 Tough")

        let morningCategory = UNNotificationCategory(identifier: "MORNING_DEVOTIONAL", actions: [startAction, prayAction], intentIdentifiers: [])
        let eveningCategory = UNNotificationCategory(identifier: "EVENING_CHECKIN", actions: [checkInGreat, checkInGood, checkInTough], intentIdentifiers: [])

        center.setNotificationCategories([morningCategory, eveningCategory])
    }
}
