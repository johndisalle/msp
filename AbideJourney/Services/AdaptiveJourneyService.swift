import Foundation
import SwiftData

/// Analyzes evening check-in data and adapts upcoming journey content.
/// - Missed days trigger grace messages
/// - Low ratings shift focus toward encouragement
/// - Sustained engagement unlocks deeper content
final class AdaptiveJourneyService {
    static let shared = AdaptiveJourneyService()

    private init() {}

    // MARK: - Check-In Analysis

    struct WeeklyAnalysis {
        let averageRating: Double       // 1.0 (missed) to 5.0 (great)
        let missedDays: Int
        let completionRate: Double      // 0.0 to 1.0
        let actionStepRate: Double      // 0.0 to 1.0
        let prayerMinutes: Int
        let sentiment: Sentiment

        enum Sentiment {
            case struggling     // avg < 2.5 or missed > 2
            case needsGrace     // avg < 3.5 or missed == 1-2
            case steady         // avg 3.5-4.0
            case thriving       // avg > 4.0 and high completion
        }
    }

    /// Analyze the last 7 days of check-ins for a journey.
    func analyzeRecentWeek(journey: Journey) -> WeeklyAnalysis {
        let recentDays = journey.days
            .filter { $0.isCompleted }
            .sorted { $0.dayNumber > $1.dayNumber }
            .prefix(7)

        let checkIns = recentDays.compactMap { $0.checkIns.first }

        guard !checkIns.isEmpty else {
            return WeeklyAnalysis(
                averageRating: 3.0,
                missedDays: 0,
                completionRate: 0,
                actionStepRate: 0,
                prayerMinutes: 0,
                sentiment: .steady
            )
        }

        let ratingValues = checkIns.map { ratingToScore($0.rating) }
        let averageRating = ratingValues.reduce(0, +) / Double(ratingValues.count)

        let missedDays = checkIns.filter { $0.rating == .missed }.count

        let expectedDays = min(7, journey.currentDay)
        let completionRate = expectedDays > 0 ? Double(recentDays.count) / Double(expectedDays) : 0

        let totalPossibleSteps = checkIns.reduce(0) { $0 + $1.totalActionSteps }
        let completedSteps = checkIns.reduce(0) { $0 + $1.completedActionSteps }
        let actionStepRate = totalPossibleSteps > 0 ? Double(completedSteps) / Double(totalPossibleSteps) : 0

        let prayerMinutes = checkIns.reduce(0) { $0 + $1.prayerMinutes }

        let sentiment: WeeklyAnalysis.Sentiment
        if averageRating < 2.5 || missedDays > 2 {
            sentiment = .struggling
        } else if averageRating < 3.5 || missedDays >= 1 {
            sentiment = .needsGrace
        } else if averageRating > 4.0 && completionRate > 0.85 {
            sentiment = .thriving
        } else {
            sentiment = .steady
        }

        return WeeklyAnalysis(
            averageRating: averageRating,
            missedDays: missedDays,
            completionRate: completionRate,
            actionStepRate: actionStepRate,
            prayerMinutes: prayerMinutes,
            sentiment: sentiment
        )
    }

    // MARK: - Content Adaptation

    /// Adapt the next day's content based on recent check-in patterns.
    /// Called when completing a day, modifies upcoming unlocked days.
    func adaptUpcomingContent(journey: Journey, analysis: WeeklyAnalysis) {
        let upcomingDays = journey.days
            .filter { !$0.isCompleted }
            .sorted { $0.dayNumber < $1.dayNumber }

        guard let nextDay = upcomingDays.first else { return }

        switch analysis.sentiment {
        case .struggling:
            injectGraceContent(into: nextDay, analysis: analysis)
        case .needsGrace:
            softenContent(into: nextDay, analysis: analysis)
        case .thriving:
            enrichContent(into: nextDay, analysis: analysis)
        case .steady:
            break // No adaptation needed
        }

        // Adjust focus areas for the rest of the week if struggling with a specific area
        if analysis.actionStepRate < 0.3 {
            simplifyActionSteps(for: upcomingDays.prefix(3))
        }
    }

    // MARK: - Grace Messages (for struggling users)

    private func injectGraceContent(into day: JourneyDay, analysis: WeeklyAnalysis) {
        let gracePrefix: String
        if analysis.missedDays > 2 {
            gracePrefix = "Welcome back. Missing days doesn't mean missing God's love — He's been with you the whole time. "
        } else {
            gracePrefix = "This journey isn't about perfection — it's about showing up. God meets you right where you are today. "
        }

        day.devotionalText = gracePrefix + day.devotionalText

        // Add a gentler action step
        var steps = day.actionSteps
        steps.insert(ActionStep(text: "Take a deep breath and tell God one thing you're grateful for right now"), at: 0)
        day.actionSteps = steps

        day.reflectionPrompt = graceReflectionPrompt(for: analysis)
    }

    private func softenContent(into day: JourneyDay, analysis: WeeklyAnalysis) {
        if analysis.missedDays > 0 {
            let encouragement = "It's okay to have missed a day. God's mercies are new every morning. "
            day.devotionalText = encouragement + day.devotionalText
        }

        day.reflectionPrompt = "What's one small thing you can thank God for today? Start there — that's enough."
    }

    private func enrichContent(into day: JourneyDay, analysis: WeeklyAnalysis) {
        // Add a bonus challenge for thriving users
        var steps = day.actionSteps
        steps.append(ActionStep(text: "Challenge: Share today's scripture or one insight with someone"))
        day.actionSteps = steps
    }

    private func simplifyActionSteps<S: Sequence>(for days: S) where S.Element == JourneyDay {
        for day in days {
            if day.actionSteps.count > 2 {
                // Keep only the first two, most essential steps
                day.actionSteps = Array(day.actionSteps.prefix(2))
            }
        }
    }

    // MARK: - Helpers

    private func ratingToScore(_ rating: CheckInRating) -> Double {
        switch rating {
        case .great: return 5.0
        case .good: return 4.0
        case .okay: return 3.0
        case .tough: return 2.0
        case .missed: return 1.0
        }
    }

    private func graceReflectionPrompt(for analysis: WeeklyAnalysis) -> String {
        let prompts = [
            "What's one thing that's been making your days harder? Bring it to God honestly.",
            "If you could ask God for one thing right now — no filter — what would it be?",
            "Where in your life do you most need to feel God's presence today?",
            "What would grace look like for you this week? How can you extend it to yourself?",
        ]
        return prompts[Int.random(in: 0..<prompts.count)]
    }
}
