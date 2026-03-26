import Foundation
import SwiftData

@Model
final class QuizResponse {
    var id: UUID = UUID()
    var questionId: String = ""
    var answer: String = ""
    var numericValue: Double?
    var answeredAt: Date = Date()

    var user: UserProfile?

    init(questionId: String, answer: String, numericValue: Double? = nil) {
        self.id = UUID()
        self.questionId = questionId
        self.answer = answer
        self.numericValue = numericValue
        self.answeredAt = Date()
    }
}

// MARK: - Quiz Questions

struct QuizQuestion: Identifiable {
    let id: String
    let text: String
    let type: QuestionType
    let options: [String]
    let category: DiscipleshipArea

    enum QuestionType {
        case multipleChoice
        case slider(min: Double, max: Double, step: Double)
        case multiSelect
    }
}

extension QuizQuestion {
    static let onboardingQuestions: [QuizQuestion] = [
        QuizQuestion(
            id: "bible_reading",
            text: "How often do you spend time in Scripture?",
            type: .multipleChoice,
            options: ["Daily", "A few times a week", "Weekly", "Rarely", "I'm just starting"],
            category: .scripture
        ),
        QuizQuestion(
            id: "prayer_consistency",
            text: "How often do you set aside time to pray?",
            type: .multipleChoice,
            options: ["Every day", "A few times a week", "Once a week", "When I remember", "I'm trying to start"],
            category: .prayer
        ),
        QuizQuestion(
            id: "biggest_obstacles",
            text: "What feels like the biggest barrier in your walk with God right now?",
            type: .multiSelect,
            options: ["Doubt or uncertainty", "Too busy to slow down", "Patterns I can't break", "Feeling alone in my faith", "God feels distant", "Not sure where to begin"],
            category: .obedience
        ),
        QuizQuestion(
            id: "worship_frequency",
            text: "How connected are you to a local church?",
            type: .multipleChoice,
            options: ["Very — I'm there weekly", "Somewhat — a couple times a month", "Loosely — here and there", "Not right now", "Looking for one"],
            category: .worship
        ),
        QuizQuestion(
            id: "community_level",
            text: "How supported do you feel by a faith community right now?",
            type: .multipleChoice,
            options: ["Very supported", "Somewhat supported", "A little, but I want more", "Not really", "I don't have one yet"],
            category: .community
        ),
        QuizQuestion(
            id: "life_events",
            text: "Is there anything happening in your life right now that's shaping your faith?",
            type: .multiSelect,
            options: ["Grief or loss", "A big life change", "A breakthrough or answered prayer", "Relationship struggles", "Health challenges", "Nothing specific"],
            category: .prayer
        ),
        QuizQuestion(
            id: "growth_desire",
            text: "If God could grow one thing in you over the next 40 days, what would it be?",
            type: .multipleChoice,
            options: ["A deeper prayer life", "Understanding the Bible better", "Actually living out my faith", "Real community", "Confidence to share my story", "Peace in the chaos"],
            category: .scripture
        )
    ]
}
