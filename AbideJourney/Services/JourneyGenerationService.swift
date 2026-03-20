import Foundation
import SwiftData

/// Generates personalized 40-day journey content based on quiz responses
final class JourneyGenerationService {
    static let shared = JourneyGenerationService()

    private init() {}

    func generateJourney(
        for profile: UserProfile,
        quizResponses: [QuizResponse],
        context: ModelContext
    ) -> Journey {
        let analysis = analyzeResponses(quizResponses)
        let theme = determineTheme(from: analysis, maturity: profile.spiritualMaturity)
        let focusAreas = determineFocusAreas(from: analysis)

        let journey = Journey(
            title: theme.rawValue,
            subtitle: generateSubtitle(for: theme, maturity: profile.spiritualMaturity),
            totalDays: 40,
            theme: theme,
            focusAreas: focusAreas
        )
        journey.user = profile

        let days = generateDays(theme: theme, focusAreas: focusAreas, analysis: analysis)
        for day in days {
            day.journey = journey
            context.insert(day)
        }
        journey.days = days

        context.insert(journey)
        return journey
    }

    // MARK: - Analysis

    private struct QuizAnalysis {
        var prayerScore: Double = 5.0
        var scriptureScore: Double = 5.0
        var obedienceScore: Double = 5.0
        var communityScore: Double = 5.0
        var sharingScore: Double = 5.0
        var obstacles: [String] = []
        var lifeEvents: [String] = []
        var desiredGrowthArea: String = ""
    }

    private func analyzeResponses(_ responses: [QuizResponse]) -> QuizAnalysis {
        var analysis = QuizAnalysis()

        for response in responses {
            switch response.questionId {
            case "prayer_consistency":
                analysis.prayerScore = response.numericValue ?? 5.0
            case "community_level":
                analysis.communityScore = response.numericValue ?? 5.0
            case "obedience_struggle":
                analysis.obedienceScore = 10 - (response.numericValue ?? 5.0)
            case "spiritual_dryness":
                let mapping: [String: Double] = ["Rarely": 8, "Sometimes": 6, "Often": 3, "Almost always": 1]
                analysis.prayerScore = min(analysis.prayerScore, mapping[response.answer] ?? 5)
            case "bible_reading":
                let mapping: [String: Double] = ["Daily": 10, "A few times a week": 7, "Weekly": 5, "Rarely": 2, "Never": 1]
                analysis.scriptureScore = mapping[response.answer] ?? 5
            case "biggest_obstacles":
                analysis.obstacles = response.answer.components(separatedBy: ",")
            case "life_events":
                analysis.lifeEvents = response.answer.components(separatedBy: ",")
            case "sharing_comfort":
                let mapping: [String: Double] = ["Very comfortable": 9, "Somewhat comfortable": 6, "Nervous but willing": 4, "Very uncomfortable": 2]
                analysis.sharingScore = mapping[response.answer] ?? 5
            case "growth_desire":
                analysis.desiredGrowthArea = response.answer
            default:
                break
            }
        }

        return analysis
    }

    private func determineTheme(from analysis: QuizAnalysis, maturity: SpiritualMaturity) -> JourneyTheme {
        if analysis.obstacles.contains("Doubt") {
            return .overcomingDoubt
        }
        if analysis.prayerScore < 4 || analysis.desiredGrowthArea == "Finding peace" {
            return .findingPeace
        }
        if analysis.scriptureScore < 4 || analysis.desiredGrowthArea == "Understanding Scripture" {
            return .knowingGod
        }
        if analysis.obedienceScore < 4 || analysis.desiredGrowthArea == "Living out my faith" {
            return .obeyingGod
        }
        if analysis.sharingScore < 4 || analysis.desiredGrowthArea == "Sharing with others" {
            return .sharingFaith
        }

        switch maturity {
        case .exploring, .newBeliever:
            return .knowingGod
        case .growing:
            return .spiritualGrowth
        case .mature, .leader:
            return .bearingFruit
        }
    }

    private func determineFocusAreas(from analysis: QuizAnalysis) -> [DiscipleshipArea] {
        var areas: [(DiscipleshipArea, Double)] = [
            (.prayer, analysis.prayerScore),
            (.scripture, analysis.scriptureScore),
            (.obedience, analysis.obedienceScore),
            (.community, analysis.communityScore),
            (.evangelism, analysis.sharingScore)
        ]
        // Lower scores get prioritized (more need)
        areas.sort { $0.1 < $1.1 }
        return areas.prefix(5).map { $0.0 }
    }

    private func generateSubtitle(for theme: JourneyTheme, maturity: SpiritualMaturity) -> String {
        return theme.subtitle
    }

    // MARK: - Day Generation

    private func generateDays(
        theme: JourneyTheme,
        focusAreas: [DiscipleshipArea],
        analysis: QuizAnalysis
    ) -> [JourneyDay] {
        let contentLibrary = ContentLibrary.shared
        var days: [JourneyDay] = []

        for dayNum in 1...40 {
            let weekNumber = (dayNum - 1) / 7
            let focusArea = focusAreas[weekNumber % focusAreas.count]
            let content = contentLibrary.content(for: theme, area: focusArea, dayInArea: dayNum)

            let day = JourneyDay(
                dayNumber: dayNum,
                scriptureReference: content.scriptureReference,
                scriptureText: content.scriptureText,
                devotionalTitle: content.devotionalTitle,
                devotionalText: content.devotionalText,
                reflectionPrompt: content.reflectionPrompt,
                focusArea: focusArea,
                theme: theme,
                actionSteps: content.actionSteps.map { ActionStep(text: $0) }
            )
            days.append(day)
        }

        return days
    }
}
