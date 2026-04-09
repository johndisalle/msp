import Foundation
import ActivityKit
import SwiftUI

// MARK: - Activity Attributes

struct DevotionalActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var dayNumber: Int
        var totalDays: Int
        var verseSnippet: String
        var verseReference: String
        var focusArea: String
        var progress: Double
        var isPrayerTimerActive: Bool
        var prayerElapsedSeconds: Int
        var prayerTargetSeconds: Int
    }

    var journeyTitle: String
}

// MARK: - Live Activity Service

final class LiveActivityService {
    static let shared = LiveActivityService()

    private var currentActivity: Activity<DevotionalActivityAttributes>?

    private init() {}

    var isSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    // MARK: - Start Devotional Activity

    func startDevotionalActivity(
        journeyTitle: String,
        dayNumber: Int,
        totalDays: Int,
        verseSnippet: String,
        verseReference: String,
        focusArea: String
    ) {
        guard isSupported else { return }

        let attributes = DevotionalActivityAttributes(journeyTitle: journeyTitle)
        let state = DevotionalActivityAttributes.ContentState(
            dayNumber: dayNumber,
            totalDays: totalDays,
            verseSnippet: verseSnippet,
            verseReference: verseReference,
            focusArea: focusArea,
            progress: Double(dayNumber) / Double(totalDays),
            isPrayerTimerActive: false,
            prayerElapsedSeconds: 0,
            prayerTargetSeconds: 0
        )

        let content = ActivityContent(state: state, staleDate: nil)

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            #if DEBUG
            print("[LiveActivity] Failed to start activity: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Update with Prayer Timer

    func updatePrayerTimer(elapsed: Int, target: Int) async {
        guard let activity = currentActivity else { return }

        var state = activity.content.state
        state.isPrayerTimerActive = true
        state.prayerElapsedSeconds = elapsed
        state.prayerTargetSeconds = target

        let content = ActivityContent(state: state, staleDate: nil)
        await activity.update(content)
    }

    // MARK: - Stop Prayer Timer

    func stopPrayerTimer() async {
        guard let activity = currentActivity else { return }

        var state = activity.content.state
        state.isPrayerTimerActive = false
        state.prayerElapsedSeconds = 0
        state.prayerTargetSeconds = 0

        let content = ActivityContent(state: state, staleDate: nil)
        await activity.update(content)
    }

    // MARK: - Update Progress

    func updateProgress(dayNumber: Int, totalDays: Int) async {
        guard let activity = currentActivity else { return }

        var state = activity.content.state
        state.dayNumber = dayNumber
        state.totalDays = totalDays
        state.progress = Double(dayNumber) / Double(totalDays)

        let content = ActivityContent(state: state, staleDate: nil)
        await activity.update(content)
    }

    // MARK: - End Activity

    func endActivity() async {
        guard let activity = currentActivity else { return }
        let state = activity.content.state
        let content = ActivityContent(state: state, staleDate: nil)
        await activity.end(content, dismissalPolicy: .immediate)
        currentActivity = nil
    }
}
