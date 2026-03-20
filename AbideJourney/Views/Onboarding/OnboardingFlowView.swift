import SwiftUI
import SwiftData

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("AccentGold", default: .orange).opacity(0.1), Color("AccentBlue", default: .blue).opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: viewModel.progress)
                    .tint(Color.accentColor)
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Content
                TabView(selection: $viewModel.currentStep) {
                    WelcomeStepView(viewModel: viewModel)
                        .tag(OnboardingViewModel.OnboardingStep.welcome)

                    NameEntryStepView(viewModel: viewModel)
                        .tag(OnboardingViewModel.OnboardingStep.nameEntry)

                    MaturityStepView(viewModel: viewModel)
                        .tag(OnboardingViewModel.OnboardingStep.maturitySelection)

                    QuizStepView(viewModel: viewModel)
                        .tag(OnboardingViewModel.OnboardingStep.quiz)

                    TranslationStepView(viewModel: viewModel)
                        .tag(OnboardingViewModel.OnboardingStep.translationSelection)

                    GeneratingStepView(viewModel: viewModel, modelContext: modelContext)
                        .tag(OnboardingViewModel.OnboardingStep.generating)

                    ReadyStepView(viewModel: viewModel) {
                        hasCompletedOnboarding = true
                    }
                    .tag(OnboardingViewModel.OnboardingStep.ready)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)
            }
        }
    }
}

// MARK: - Welcome Step

struct WelcomeStepView: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "book.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.accent)
                .symbolEffect(.pulse)
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("Abide Journey")
                    .font(.largeTitle.bold())

                Text("Your personal mentor in your pocket.\n40 days to deeper faith.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button {
                viewModel.nextStep()
            } label: {
                Text("Begin Your Journey")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .padding()
    }
}

// MARK: - Name Entry Step

struct NameEntryStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "person.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(.accent)
                    .accessibilityHidden(true)

                Text("What's your name?")
                    .font(.title2.bold())

                Text("We'll use this to personalize your journey.")
                    .foregroundStyle(.secondary)
            }

            TextField("Your name", text: $viewModel.userName)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
                .focused($isFocused)
                .onAppear { isFocused = true }

            Spacer()

            HStack {
                Button("Back") { viewModel.previousStep() }
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    viewModel.nextStep()
                } label: {
                    Label("Next", systemImage: "arrow.right")
                        .font(.headline)
                }
                .disabled(viewModel.userName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .padding()
    }
}

// MARK: - Maturity Step

struct MaturityStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Text("Where are you in your faith journey?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("This helps us tailor your experience.")
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(SpiritualMaturity.allCases, id: \.self) { maturity in
                    Button {
                        viewModel.selectedMaturity = maturity
                    } label: {
                        HStack {
                            Text(maturity.rawValue)
                                .font(.body)
                            Spacer()
                            if viewModel.selectedMaturity == maturity {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.accent)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.selectedMaturity == maturity ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.selectedMaturity == maturity ? Color.accentColor : .clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(maturity.rawValue)
                    .accessibilityAddTraits(viewModel.selectedMaturity == maturity ? .isSelected : [])
                }
            }
            .padding(.horizontal)

            Spacer()

            HStack {
                Button("Back") { viewModel.previousStep() }
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    viewModel.nextStep()
                } label: {
                    Label("Next", systemImage: "arrow.right")
                        .font(.headline)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .padding()
    }
}

// MARK: - Quiz Step

struct QuizStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var sliderValue: Double = 5

    var body: some View {
        VStack(spacing: 24) {
            if let question = viewModel.currentQuestion {
                // Quiz progress
                HStack {
                    Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.questions.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)

                ProgressView(value: viewModel.quizProgress)
                    .tint(.accent)
                    .padding(.horizontal)

                Spacer()

                Text(question.text)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                switch question.type {
                case .multipleChoice:
                    VStack(spacing: 10) {
                        ForEach(question.options, id: \.self) { option in
                            Button {
                                viewModel.answerQuestion(option)
                            } label: {
                                Text(option)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)

                case .slider(let min, let max, let step):
                    VStack(spacing: 16) {
                        Text("\(Int(sliderValue))")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.accent)

                        Slider(value: $sliderValue, in: min...max, step: step)
                            .tint(.accent)
                            .padding(.horizontal, 32)

                        HStack {
                            Text("Low")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("High")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 32)

                        Button("Continue") {
                            viewModel.answerQuestion("\(Int(sliderValue))", numericValue: sliderValue)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                case .multiSelect:
                    MultiSelectQuizView(options: question.options) { selected in
                        viewModel.answerQuestion(selected.joined(separator: ","))
                    }
                }

                Spacer()

                HStack {
                    Button("Back") {
                        viewModel.previousQuestion()
                    }
                    .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .padding()
    }
}

struct MultiSelectQuizView: View {
    let options: [String]
    let onComplete: ([String]) -> Void
    @State private var selected: Set<String> = []

    var body: some View {
        VStack(spacing: 10) {
            ForEach(options, id: \.self) { option in
                Button {
                    if selected.contains(option) {
                        selected.remove(option)
                    } else {
                        selected.insert(option)
                    }
                } label: {
                    HStack {
                        Text(option)
                        Spacer()
                        Image(systemName: selected.contains(option) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selected.contains(option) ? .accent : .secondary)
                            .accessibilityHidden(true)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selected.contains(option) ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected.contains(option) ? .isSelected : [])
            }

            Button("Continue") {
                onComplete(Array(selected))
            }
            .buttonStyle(.borderedProminent)
            .disabled(selected.isEmpty)
            .padding(.top)
        }
        .padding(.horizontal)
    }
}

// MARK: - Translation Step

struct TranslationStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "text.book.closed.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.accent)
                    .accessibilityHidden(true)

                Text("Choose Your Bible Translation")
                    .font(.title2.bold())

                Text("You can change this anytime.")
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                ForEach(BibleTranslation.allCases, id: \.self) { translation in
                    Button {
                        viewModel.selectedTranslation = translation
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(translation.rawValue)
                                    .font(.headline)
                                Text(translation.fullName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if viewModel.selectedTranslation == translation {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.accent)
                                    .accessibilityHidden(true)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.selectedTranslation == translation ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(translation.rawValue), \(translation.fullName)")
                    .accessibilityAddTraits(viewModel.selectedTranslation == translation ? .isSelected : [])
                }
            }
            .padding(.horizontal)

            Spacer()

            HStack {
                Button("Back") { viewModel.previousStep() }
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    viewModel.nextStep()
                } label: {
                    Label("Generate My Journey", systemImage: "sparkles")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .padding()
    }
}

// MARK: - Generating Step

struct GeneratingStepView: View {
    let viewModel: OnboardingViewModel
    let modelContext: ModelContext
    @State private var hasStarted = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            if let errorMessage = viewModel.generationError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)

                Text("Something went wrong")
                    .font(.title3.bold())

                Text(errorMessage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Try Again") {
                    viewModel.generationError = nil
                    hasStarted = false
                }
                .buttonStyle(.borderedProminent)
            } else if viewModel.isGeneratingJourney {
                ProgressView()
                    .scaleEffect(1.5)

                Text("Crafting your personal journey...")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 64))
                    .foregroundStyle(.accent)
                    .symbolEffect(.variableColor)
                    .accessibilityHidden(true)

                Text("Ready to generate your\npersonalized 40-day journey")
                    .font(.title3)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            viewModel.generateJourney(context: modelContext)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                guard viewModel.generationError == nil else { return }
                viewModel.nextStep()
            }
        }
    }
}

// MARK: - Ready Step

struct ReadyStepView: View {
    let viewModel: OnboardingViewModel
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, options: .nonRepeating)
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("Your Journey Awaits!")
                    .font(.largeTitle.bold())

                if let journey = viewModel.generatedJourney {
                    Text(journey.title)
                        .font(.title2)
                        .foregroundStyle(.accent)

                    Text(journey.subtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Text("40 days of growth, one step at a time.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }

            Spacer()

            Button {
                onStart()
            } label: {
                Text("Start Day 1")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .padding()
    }
}

// MARK: - Color Extension

extension Color {
    init(_ name: String, default fallback: Color) {
        if UIColor(named: name) != nil {
            self.init(name)
        } else {
            self = fallback
        }
    }
}

#Preview {
    OnboardingFlowView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
