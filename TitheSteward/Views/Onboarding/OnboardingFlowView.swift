import SwiftUI
import SwiftData
import AuthenticationServices

struct OnboardingFlowView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressView(value: viewModel.progress)
                .tint(Color("AccentGold"))
                .padding(.horizontal)
                .padding(.top, 8)

            // Step content
            TabView(selection: $viewModel.currentStep) {
                WelcomeStepView()
                    .tag(OnboardingViewModel.OnboardingStep.welcome)

                SignInStepView(viewModel: viewModel)
                    .tag(OnboardingViewModel.OnboardingStep.signIn)

                FaithQuizStepView(viewModel: viewModel)
                    .tag(OnboardingViewModel.OnboardingStep.faithQuiz)

                IncomeSetupStepView(viewModel: viewModel)
                    .tag(OnboardingViewModel.OnboardingStep.incomeSetup)

                DebtOverviewStepView(viewModel: viewModel)
                    .tag(OnboardingViewModel.OnboardingStep.debtOverview)

                ChurchSetupStepView(viewModel: viewModel)
                    .tag(OnboardingViewModel.OnboardingStep.churchSetup)

                RemindersStepView(viewModel: viewModel)
                    .tag(OnboardingViewModel.OnboardingStep.reminders)

                CompleteStepView(viewModel: viewModel)
                    .tag(OnboardingViewModel.OnboardingStep.complete)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: viewModel.currentStep)

            // Navigation buttons
            HStack {
                if viewModel.currentStep != .welcome {
                    Button("Back") {
                        viewModel.previousStep()
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                if viewModel.currentStep == .complete {
                    Button("Begin Your Journey") {
                        viewModel.saveProfile()
                        hasCompletedOnboarding = true
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color("AccentGold"))
                    .clipShape(Capsule())
                } else {
                    Button("Continue") {
                        viewModel.nextStep()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(viewModel.canProceed ? Color("AccentGold") : Color.gray)
                    .clipShape(Capsule())
                    .disabled(!viewModel.canProceed)
                }
            }
            .padding()
        }
        .background(Color("BackgroundPrimary"))
        .onAppear {
            viewModel.configure(modelContext: modelContext)
        }
    }
}

// MARK: - Step Views

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Color("AccentGold"))

            Text("Tithe Steward")
                .font(.largeTitle.bold())

            Text("Tithe First, Steward Faithfully")
                .font(.title3)
                .foregroundColor(.secondary)

            Text("Turn Your Finances into Worship")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Text("\"For where your treasure is, there your heart will be also.\"")
                .font(.callout.italic())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text("— Matthew 6:21")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
    }
}

struct SignInStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(Color("AccentGold"))

            Text("Secure Your Journey")
                .font(.title2.bold())

            Text("Sign in to keep your data safe and synced across devices.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case .success(let authorization):
                    if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                        viewModel.displayName = [credential.fullName?.givenName, credential.fullName?.familyName]
                            .compactMap { $0 }
                            .joined(separator: " ")
                    }
                    viewModel.nextStep()
                case .failure:
                    break
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal, 40)

            Button("Skip for now") {
                viewModel.nextStep()
            }
            .foregroundColor(.secondary)
            .font(.callout)

            Spacer()
        }
        .padding()
    }
}

struct FaithQuizStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text(viewModel.currentStep.title)
                .font(.title2.bold())
                .padding(.top, 32)

            Text(viewModel.currentStep.subtitle)
                .font(.body)
                .foregroundColor(.secondary)

            Text("Where are you on your giving journey?")
                .font(.headline)
                .padding(.top, 16)

            ForEach(TithingCommitment.allCases, id: \.self) { commitment in
                Button {
                    viewModel.tithingCommitment = commitment
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(commitment.rawValue)
                                .font(.headline)
                            Text(commitment.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if viewModel.tithingCommitment == commitment {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color("AccentGold"))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.tithingCommitment == commitment ?
                                  Color("AccentGold").opacity(0.1) : Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.tithingCommitment == commitment ?
                                    Color("AccentGold") : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Text(viewModel.tithingCommitment.encouragementVerse)
                .font(.callout.italic())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.horizontal)
    }
}

struct IncomeSetupStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text(viewModel.currentStep.title)
                .font(.title2.bold())
                .padding(.top, 32)

            Text(viewModel.currentStep.verse)
                .font(.callout.italic())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("How often are you paid?")
                    .font(.headline)

                Picker("Income Frequency", selection: $viewModel.incomeFrequency) {
                    ForEach(IncomeFrequency.allCases, id: \.self) { freq in
                        Text(freq.rawValue).tag(freq)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.top, 16)

            VStack(alignment: .leading, spacing: 8) {
                Text("Monthly take-home income")
                    .font(.headline)

                HStack {
                    Text("$")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    TextField("0", text: $viewModel.monthlyIncome)
                        .font(.title2)
                        .keyboardType(.decimalPad)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }

            if !viewModel.monthlyIncome.isEmpty {
                VStack(spacing: 8) {
                    Text("Your suggested monthly tithe")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(viewModel.suggestedTithe.currencyWhole)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color("AccentGold"))

                    Text("10% of your income")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color("AccentGold").opacity(0.1))
                .cornerRadius(16)
            }

            Toggle("Do you currently carry any debt?", isOn: $viewModel.hasDebt)
                .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal)
    }
}

struct DebtOverviewStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text(viewModel.currentStep.title)
                .font(.title2.bold())
                .padding(.top, 32)

            Image(systemName: "lock.open.fill")
                .font(.system(size: 50))
                .foregroundColor(Color("AccentGold"))

            Text("Freedom starts with honesty")
                .font(.headline)

            Text("You'll be able to add your debts in detail after setup. For now, just know that Tithe Steward will help you create a biblical plan to break free.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            VStack(spacing: 12) {
                FeatureRow(icon: "chart.line.downtrend.xyaxis", text: "Debt Snowball Calculator")
                FeatureRow(icon: "book.fill", text: "Scripture encouragement per debt")
                FeatureRow(icon: "bell.fill", text: "Payment reminders")
                FeatureRow(icon: "trophy.fill", text: "Celebrate each debt paid off")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)

            Spacer()

            Text(viewModel.currentStep.verse)
                .font(.callout.italic())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.horizontal)
    }
}

struct ChurchSetupStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text(viewModel.currentStep.title)
                .font(.title2.bold())
                .padding(.top, 32)

            Image(systemName: "building.columns.fill")
                .font(.system(size: 50))
                .foregroundColor(Color("AccentGold"))

            Text("Where do you worship?")
                .font(.headline)

            Text("Adding your church helps us personalize your tithe tracking. This is optional.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            TextField("Church name (optional)", text: $viewModel.primaryChurch)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

            Spacer()

            Text(viewModel.currentStep.verse)
                .font(.callout.italic())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.horizontal)
    }
}

struct RemindersStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text(viewModel.currentStep.title)
                .font(.title2.bold())
                .padding(.top, 32)

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 50))
                .foregroundColor(Color("AccentGold"))

            Text("We'll send gentle reminders to help you stay faithful with your giving and devotional time.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Toggle("Tithe reminders on paydays", isOn: $viewModel.enableReminders)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

            Toggle("Daily devotional reminder", isOn: .constant(true))
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

            Spacer()

            Text(viewModel.currentStep.verse)
                .font(.callout.italic())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.horizontal)
    }
}

struct CompleteStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(Color("AccentGold"))

            Text("You're Ready!")
                .font(.largeTitle.bold())

            Text("Your stewardship journey begins now")
                .font(.title3)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                if !viewModel.displayName.isEmpty {
                    SummaryRow(label: "Name", value: viewModel.displayName)
                }
                SummaryRow(label: "Commitment", value: viewModel.tithingCommitment.rawValue)
                if !viewModel.monthlyIncome.isEmpty {
                    SummaryRow(label: "Monthly Tithe Goal", value: viewModel.suggestedTithe.currencyWhole)
                }
                if !viewModel.primaryChurch.isEmpty {
                    SummaryRow(label: "Church", value: viewModel.primaryChurch)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)

            Spacer()

            Text("\"God loves a cheerful giver.\"")
                .font(.callout.italic())
                .foregroundColor(.secondary)

            Text("— 2 Corinthians 9:7")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Helper Views

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color("AccentGold"))
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }
}

#Preview {
    OnboardingFlowView()
}
