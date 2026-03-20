// OnboardingFlowView.swift
// FaithForge
//
// Multi-step onboarding: Welcome → Apple Sign In → Faith Assessment → Daily Goal → Done.

import SwiftUI
import SwiftData
import AuthenticationServices

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(FirebaseAuthStub.self) private var authService

    @State private var currentStep: OnboardingStep = .welcome
    @State private var assessmentAnswers: [FaithCategory: Int] = [:]
    @State private var selectedGoal: DailyGoalIntensity = .moderate
    @State private var userName: String = ""

    enum OnboardingStep: CaseIterable {
        case welcome, signIn, assessment, dailyGoal, complete
    }

    var body: some View {
        ZStack {
            Color("BackgroundPrimary").ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                stepIndicator

                TabView(selection: $currentStep) {
                    welcomeStep.tag(OnboardingStep.welcome)
                    signInStep.tag(OnboardingStep.signIn)
                    assessmentStep.tag(OnboardingStep.assessment)
                    dailyGoalStep.tag(OnboardingStep.dailyGoal)
                    completeStep.tag(OnboardingStep.complete)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(Array(OnboardingStep.allCases.enumerated()), id: \.offset) { index, step in
                Capsule()
                    .fill(currentStep == step ? Color("FaithBlue") : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "cross.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color("FaithBlue"))

            VStack(spacing: 12) {
                Text("Welcome to FaithForge")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color("TextPrimary"))

                Text("Build spiritual habits that last.\nQuests, XP, and Faith Rings for your journey.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                currentStep = .signIn
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("FaithBlue"))
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Step 2: Sign In

    private var signInStep: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 56))
                .foregroundStyle(Color("FaithGreen"))

            VStack(spacing: 12) {
                Text("Sign In")
                    .font(.title.bold())
                    .foregroundStyle(Color("TextPrimary"))

                Text("Sign in to save your progress across devices.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    authService.handleAppleSignIn(result: result)
                    if authService.isSignedIn {
                        userName = authService.displayName ?? ""
                        currentStep = .assessment
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)

                Button("Continue as Guest") {
                    authService.continueAsGuest()
                    currentStep = .assessment
                }
                .font(.subheadline)
                .foregroundStyle(Color("FaithBlue"))
            }

            Spacer()
        }
    }

    // MARK: - Step 3: Faith Assessment (6 questions)

    private var assessmentStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Faith Assessment")
                        .font(.title.bold())
                        .foregroundStyle(Color("TextPrimary"))

                    Text("Rate your current comfort level in each area.\nWe'll personalize your quests based on this.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                ForEach(FaithCategory.allCases) { category in
                    AssessmentRow(
                        category: category,
                        rating: Binding(
                            get: { assessmentAnswers[category] ?? 3 },
                            set: { assessmentAnswers[category] = $0 }
                        )
                    )
                }

                Button {
                    currentStep = .dailyGoal
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("FaithBlue"))
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Step 4: Daily Goal Picker

    private var dailyGoalStep: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "target")
                .font(.system(size: 56))
                .foregroundStyle(Color("FaithGold"))

            VStack(spacing: 8) {
                Text("Set Your Daily Goal")
                    .font(.title.bold())
                    .foregroundStyle(Color("TextPrimary"))

                Text("How much time can you commit each day?")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(DailyGoalIntensity.allCases, id: \.rawValue) { intensity in
                    GoalOptionRow(
                        intensity: intensity,
                        isSelected: selectedGoal == intensity
                    ) {
                        selectedGoal = intensity
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                currentStep = .complete
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("FaithBlue"))
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Step 5: Complete

    private var completeStep: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color("FaithGreen"))
                .symbolEffect(.bounce, options: .repeating.speed(0.5))

            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color("TextPrimary"))

                Text("Your personalized faith journey begins now.\nLet's forge some holy habits!")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                completeOnboarding()
            } label: {
                Text("Start My Journey")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("FaithGreen"))
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Save & Complete

    private func completeOnboarding() {
        // Determine weak areas (categories rated <= 2)
        let weakAreas = assessmentAnswers
            .filter { $0.value <= 2 }
            .map { $0.key.rawValue }

        let profile = UserProfile(
            displayName: userName.isEmpty ? "Pilgrim" : userName,
            dailyGoal: selectedGoal,
            weakAreas: weakAreas
        )
        profile.onboardingCompleted = true
        modelContext.insert(profile)
        try? modelContext.save()
    }
}

// MARK: - Assessment Row

private struct AssessmentRow: View {
    let category: FaithCategory
    @Binding var rating: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(category.rawValue, systemImage: category.icon)
                .font(.headline)
                .foregroundStyle(Color("TextPrimary"))

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        rating = value
                    } label: {
                        Circle()
                            .fill(value <= rating ? Color("FaithBlue") : Color.gray.opacity(0.2))
                            .frame(width: 36, height: 36)
                            .overlay {
                                Text("\(value)")
                                    .font(.caption.bold())
                                    .foregroundStyle(value <= rating ? .white : .secondary)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(value) out of 5 for \(category.rawValue)")
                }

                Spacer()
            }
        }
        .faithCard()
        .padding(.horizontal, 24)
    }
}

// MARK: - Goal Option Row

private struct GoalOptionRow: View {
    let intensity: DailyGoalIntensity
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(intensity.rawValue)
                        .font(.headline)
                        .foregroundStyle(Color("TextPrimary"))
                    Text("\(intensity.questCount) quests/day \u{2022} \(intensity.subtitle)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color("FaithBlue") : .secondary)
            }
            .faithCard()
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color("FaithBlue") : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(intensity.rawValue), \(intensity.subtitle)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    OnboardingFlowView()
        .modelContainer(for: [UserProfile.self], inMemory: true)
        .environment(FirebaseAuthStub())
}
