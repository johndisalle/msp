import Foundation
import SwiftData
import SwiftUI

@Observable
final class OnboardingViewModel {
    var currentStep: OnboardingStep = .welcome
    var currentQuestionIndex = 0
    var userName = ""
    var selectedMaturity: SpiritualMaturity = .exploring
    var selectedTranslation: BibleTranslation = .niv
    var answers: [String: QuizAnswer] = [:]
    var isGeneratingJourney = false
    var generatedJourney: Journey?
    var generationError: String?

    struct QuizAnswer {
        let answer: String
        let numericValue: Double?
    }

    enum OnboardingStep: CaseIterable {
        case welcome
        case nameEntry
        case maturitySelection
        case quiz
        case translationSelection
        case generating
        case ready
    }

    var questions: [QuizQuestion] {
        QuizQuestion.onboardingQuestions
    }

    var currentQuestion: QuizQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }

    var progress: Double {
        let totalSteps = Double(OnboardingStep.allCases.count)
        let currentIndex = Double(OnboardingStep.allCases.firstIndex(of: currentStep) ?? 0)
        return currentIndex / totalSteps
    }

    var quizProgress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex) / Double(questions.count)
    }

    // MARK: - Navigation

    func nextStep() {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              currentIndex + 1 < OnboardingStep.allCases.count else { return }
        withAnimation(.easeInOut) {
            currentStep = OnboardingStep.allCases[currentIndex + 1]
        }
    }

    func previousStep() {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              currentIndex > 0 else { return }
        withAnimation(.easeInOut) {
            currentStep = OnboardingStep.allCases[currentIndex - 1]
        }
    }

    func answerQuestion(_ answer: String, numericValue: Double? = nil) {
        guard let question = currentQuestion else { return }
        answers[question.id] = QuizAnswer(answer: answer, numericValue: numericValue)

        if currentQuestionIndex + 1 < questions.count {
            withAnimation {
                currentQuestionIndex += 1
            }
        } else {
            nextStep() // Move past quiz
        }
    }

    func previousQuestion() {
        if currentQuestionIndex > 0 {
            withAnimation {
                currentQuestionIndex -= 1
            }
        } else {
            previousStep()
        }
    }

    // MARK: - Journey Generation

    func generateJourney(context: ModelContext) {
        isGeneratingJourney = true

        let profile = UserProfile(
            name: userName,
            spiritualMaturity: selectedMaturity,
            preferredTranslation: selectedTranslation
        )
        context.insert(profile)

        var quizResponses: [QuizResponse] = []
        for (questionId, answer) in answers {
            let response = QuizResponse(
                questionId: questionId,
                answer: answer.answer,
                numericValue: answer.numericValue
            )
            response.user = profile
            context.insert(response)
            quizResponses.append(response)
        }

        let journey = JourneyGenerationService.shared.generateJourney(
            for: profile,
            quizResponses: quizResponses,
            context: context
        )

        do {
            try context.save()
        } catch {
            generationError = "We couldn't save your journey. Please try again."
            isGeneratingJourney = false
            return
        }

        generatedJourney = journey
        isGeneratingJourney = false

        // Schedule notifications
        Task {
            let granted = await NotificationService.shared.requestAuthorization()
            if granted {
                NotificationService.shared.registerCategories()
                if let firstDay = journey.days.first {
                    NotificationService.shared.scheduleMorningReminder(
                        at: profile.notificationMorningTime,
                        dayNumber: 1,
                        verseSnippet: String(firstDay.scriptureText.prefix(60))
                    )
                }
            }
        }
    }
}
