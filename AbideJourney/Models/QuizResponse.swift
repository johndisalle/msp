import Foundation
import SwiftData

@Model
final class QuizResponse {
    var id: UUID
    var questionId: String
    var answer: String
    var numericValue: Double?
    var answeredAt: Date

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
            id: "spiritual_dryness",
            text: "How often do you feel spiritually dry?",
            type: .multipleChoice,
            options: ["Rarely", "Sometimes", "Often", "Almost always"],
            category: .prayer
        ),
        QuizQuestion(
            id: "prayer_consistency",
            text: "How often do you set aside time to pray each week?",
            type: .slider(min: 1, max: 10, step: 1),
            options: [],
            category: .prayer
        ),
        QuizQuestion(
            id: "bible_reading",
            text: "How often do you read the Bible?",
            type: .multipleChoice,
            options: ["Daily", "A few times a week", "Weekly", "Rarely", "Never"],
            category: .scripture
        ),
        QuizQuestion(
            id: "biggest_obstacles",
            text: "What are your biggest spiritual obstacles?",
            type: .multiSelect,
            options: ["Doubt", "Busyness", "Sin patterns", "Lack of community", "Feeling distant from God", "Not knowing where to start"],
            category: .obedience
        ),
        QuizQuestion(
            id: "worship_frequency",
            text: "How often do you attend worship or church?",
            type: .multipleChoice,
            options: ["Weekly", "A couple times a month", "Monthly", "Rarely", "Not currently"],
            category: .worship
        ),
        QuizQuestion(
            id: "community_level",
            text: "Rate your involvement in a faith community",
            type: .slider(min: 1, max: 10, step: 1),
            options: [],
            category: .community
        ),
        QuizQuestion(
            id: "sharing_comfort",
            text: "How comfortable are you sharing your faith?",
            type: .multipleChoice,
            options: ["Very comfortable", "Somewhat comfortable", "Nervous but willing", "Very uncomfortable"],
            category: .evangelism
        ),
        QuizQuestion(
            id: "life_events",
            text: "Any recent life events affecting your faith?",
            type: .multiSelect,
            options: ["Grief or loss", "Major transition", "Victory or breakthrough", "Relationship change", "Health challenge", "None of these"],
            category: .prayer
        ),
        QuizQuestion(
            id: "obedience_struggle",
            text: "How much do you struggle with applying what you learn from Scripture?",
            type: .slider(min: 1, max: 10, step: 1),
            options: [],
            category: .obedience
        ),
        QuizQuestion(
            id: "growth_desire",
            text: "Which area do you most want to grow in?",
            type: .multipleChoice,
            options: ["Deeper prayer life", "Understanding Scripture", "Living out my faith", "Building community", "Sharing with others", "Finding peace"],
            category: .scripture
        )
    ]
}
