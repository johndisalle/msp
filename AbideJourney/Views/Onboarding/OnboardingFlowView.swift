import SwiftUI
import SwiftData
import AuthenticationServices

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            AJTheme.morningGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ProgressView(value: viewModel.progress)
                    .tint(AJTheme.sage)
                    .padding(.horizontal)
                    .padding(.top, 8)

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
                        Analytics.onboardingCompleted(maturity: viewModel.selectedMaturity.rawValue)
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
    @State private var appeared = false
    @State private var authError: String?
    @State private var showingSignUp = false
    @State private var showingSignIn = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AJTheme.paddingLarge) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(AJTheme.sage.opacity(0.2), lineWidth: 2)
                        .frame(width: 140, height: 140)

                    Circle()
                        .fill(AJTheme.sage.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AJTheme.sage)
                }
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)
                .accessibilityHidden(true)

                Text("Abide Journey")
                    .font(AJTheme.titleFont)
                    .foregroundColor(AJTheme.primaryText)
                    .opacity(appeared ? 1 : 0)

                Text("40 days that will change\nhow you walk with God.")
                    .font(.system(.title3, design: .serif))
                    .foregroundStyle(AJTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(appeared ? 1 : 0)
            }

            VStack(spacing: 12) {
                featureRow(icon: "sunrise.fill", color: AJTheme.gold, text: "Daily devotionals written for you")
                featureRow(icon: "hands.sparkles.fill", color: AJTheme.sage, text: "Guided prayer and reflection")
                featureRow(icon: "chart.line.uptrend.xyaxis", color: AJTheme.sandstone, text: "Track your spiritual growth")
            }
            .padding(.horizontal, AJTheme.paddingLarge)
            .opacity(appeared ? 1 : 0)

            Spacer()

            VStack(spacing: 12) {
                // Sign in with Apple
                SignInWithAppleButton(.signUp, onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                }, onCompletion: { result in
                    handleAppleSignIn(result)
                })
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: AJTheme.cornerRadius))
                .padding(.horizontal, AJTheme.paddingXLarge)

                // Create account with email
                Button {
                    showingSignUp = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                        Text("Sign Up with Email")
                    }
                }
                .buttonStyle(AJSecondaryButtonStyle())
                .padding(.horizontal, AJTheme.paddingXLarge)

                // Sign in for returning users
                Button {
                    showingSignIn = true
                } label: {
                    Text("Already have an account? Sign In")
                        .font(.system(.subheadline, design: .serif, weight: .medium))
                        .foregroundStyle(AJTheme.sage)
                }

                // Skip
                Button {
                    viewModel.nextStep()
                } label: {
                    Text("Continue without Account")
                        .font(.system(.caption, design: .serif))
                        .foregroundStyle(AJTheme.secondaryText)
                }

                if let authError {
                    Text(authError)
                        .font(AJTheme.captionFont)
                        .foregroundStyle(AJTheme.destructive)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AJTheme.paddingXLarge)
                }
            }
            .padding(.bottom, 40)
            .opacity(appeared ? 1 : 0)
        }
        .padding()
        .onAppear {
            Analytics.onboardingStarted()
            withAnimation(.easeOut(duration: 0.8)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showingSignUp) {
            EmailSignUpSheet(viewModel: viewModel, authError: $authError)
        }
        .sheet(isPresented: $showingSignIn) {
            EmailSignInSheet(viewModel: viewModel, authError: $authError)
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        do {
            try AuthService.shared.handleAuthorization(result)
            if let fullName = AuthService.shared.userFullName, !fullName.isEmpty {
                viewModel.userName = fullName
            }
            viewModel.nextStep()
        } catch let error as ASAuthorizationError where error.code == .canceled {
            // User cancelled
        } catch {
            authError = error.localizedDescription
        }
    }

    private func featureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
            }
            Text(text)
                .font(.system(.subheadline, design: .serif))
                .foregroundStyle(AJTheme.secondaryText)
            Spacer()
        }
    }
}

// MARK: - Email Sign Up Sheet

struct EmailSignUpSheet: View {
    let viewModel: OnboardingViewModel
    @Binding var authError: String?
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var sheetError: String?
    @State private var isPasswordVisible = false
    @FocusState private var focusedField: Field?

    enum Field { case name, email, password, confirm }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AJTheme.paddingLarge) {
                    VStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 40))
                            .foregroundStyle(AJTheme.sage)
                            .accessibilityHidden(true)

                        Text("Create Your Account")
                            .font(AJTheme.headlineFont)
                            .foregroundColor(AJTheme.primaryText)

                        Text("Your journey starts here.")
                            .font(AJTheme.bodyFont)
                            .foregroundStyle(AJTheme.secondaryText)
                    }
                    .padding(.top, AJTheme.paddingLarge)

                    VStack(spacing: AJTheme.paddingMedium) {
                        AuthTextField(
                            label: "Full Name",
                            icon: "person.fill",
                            text: $name,
                            isSecure: false
                        )
                        .focused($focusedField, equals: .name)
                        .textContentType(.name)
                        .submitLabel(.next)

                        AuthTextField(
                            label: "Email",
                            icon: "envelope.fill",
                            text: $email,
                            isSecure: false
                        )
                        .focused($focusedField, equals: .email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .submitLabel(.next)

                        AuthTextField(
                            label: "Password",
                            icon: "lock.fill",
                            text: $password,
                            isSecure: true
                        )
                        .focused($focusedField, equals: .password)
                        .textContentType(.newPassword)
                        .submitLabel(.next)

                        AuthTextField(
                            label: "Confirm Password",
                            icon: "lock.fill",
                            text: $confirmPassword,
                            isSecure: true
                        )
                        .focused($focusedField, equals: .confirm)
                        .textContentType(.newPassword)
                        .submitLabel(.done)
                    }
                    .padding(.horizontal, AJTheme.paddingLarge)

                    if let sheetError {
                        Text(sheetError)
                            .font(AJTheme.captionFont)
                            .foregroundStyle(AJTheme.destructive)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AJTheme.paddingLarge)
                    }

                    Button {
                        createAccount()
                    } label: {
                        Text("Create Account")
                    }
                    .buttonStyle(AJPrimaryButtonStyle())
                    .padding(.horizontal, AJTheme.paddingLarge)
                    .disabled(name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                }
            }
            .background(AJTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AJTheme.sage)
                }
            }
            .onSubmit {
                switch focusedField {
                case .name: focusedField = .email
                case .email: focusedField = .password
                case .password: focusedField = .confirm
                case .confirm: createAccount()
                case nil: break
                }
            }
        }
    }

    private func createAccount() {
        sheetError = nil

        guard password == confirmPassword else {
            sheetError = "Passwords don't match."
            return
        }

        do {
            try AuthService.shared.signUp(name: name, email: email, password: password)
            viewModel.userName = name
            dismiss()
            viewModel.nextStep()
        } catch {
            sheetError = error.localizedDescription
        }
    }
}

// MARK: - Email Sign In Sheet

struct EmailSignInSheet: View {
    let viewModel: OnboardingViewModel
    @Binding var authError: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var email = ""
    @State private var password = ""
    @State private var sheetError: String?
    @FocusState private var focusedField: Field?

    enum Field { case email, password }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AJTheme.paddingLarge) {
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(AJTheme.sage)
                            .accessibilityHidden(true)

                        Text("Welcome Back")
                            .font(AJTheme.headlineFont)
                            .foregroundColor(AJTheme.primaryText)

                        Text("Sign in to continue your journey.")
                            .font(AJTheme.bodyFont)
                            .foregroundStyle(AJTheme.secondaryText)
                    }
                    .padding(.top, AJTheme.paddingLarge)

                    VStack(spacing: AJTheme.paddingMedium) {
                        AuthTextField(
                            label: "Email",
                            icon: "envelope.fill",
                            text: $email,
                            isSecure: false
                        )
                        .focused($focusedField, equals: .email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .submitLabel(.next)

                        AuthTextField(
                            label: "Password",
                            icon: "lock.fill",
                            text: $password,
                            isSecure: true
                        )
                        .focused($focusedField, equals: .password)
                        .textContentType(.password)
                        .submitLabel(.done)
                    }
                    .padding(.horizontal, AJTheme.paddingLarge)

                    if let sheetError {
                        Text(sheetError)
                            .font(AJTheme.captionFont)
                            .foregroundStyle(AJTheme.destructive)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AJTheme.paddingLarge)
                    }

                    Button {
                        signIn()
                    } label: {
                        Text("Sign In")
                    }
                    .buttonStyle(AJPrimaryButtonStyle())
                    .padding(.horizontal, AJTheme.paddingLarge)
                    .disabled(email.isEmpty || password.isEmpty)

                    // Divider
                    HStack {
                        Rectangle().fill(AJTheme.sage.opacity(0.2)).frame(height: 1)
                        Text("or")
                            .font(.system(.caption, design: .serif))
                            .foregroundStyle(AJTheme.secondaryText)
                        Rectangle().fill(AJTheme.sage.opacity(0.2)).frame(height: 1)
                    }
                    .padding(.horizontal, AJTheme.paddingLarge)

                    // Apple sign in option
                    SignInWithAppleButton(.signIn, onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    }, onCompletion: { result in
                        do {
                            try AuthService.shared.handleAuthorization(result)
                            if let fullName = AuthService.shared.userFullName, !fullName.isEmpty {
                                viewModel.userName = fullName
                            }
                            dismiss()
                            viewModel.nextStep()
                        } catch let error as ASAuthorizationError where error.code == .canceled {
                            // cancelled
                        } catch {
                            sheetError = error.localizedDescription
                        }
                    })
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: AJTheme.cornerRadius))
                    .padding(.horizontal, AJTheme.paddingLarge)
                }
            }
            .background(AJTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AJTheme.sage)
                }
            }
            .onSubmit {
                switch focusedField {
                case .email: focusedField = .password
                case .password: signIn()
                case nil: break
                }
            }
        }
    }

    private func signIn() {
        sheetError = nil
        do {
            try AuthService.shared.signIn(email: email, password: password)
            if let name = AuthService.shared.userFullName {
                viewModel.userName = name
            }
            dismiss()
            viewModel.nextStep()
        } catch {
            sheetError = error.localizedDescription
        }
    }
}

// MARK: - Auth Text Field

struct AuthTextField: View {
    let label: String
    let icon: String
    var text: Binding<String>
    var isSecure: Bool

    @State private var isRevealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(.caption, design: .serif, weight: .medium))
                .foregroundColor(AJTheme.primaryText)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(AJTheme.sage)
                    .frame(width: 20)

                if isSecure && !isRevealed {
                    SecureField(label, text: text)
                        .font(AJTheme.bodyFont)
                } else {
                    TextField(label, text: text)
                        .font(AJTheme.bodyFont)
                }

                if isSecure {
                    Button {
                        isRevealed.toggle()
                    } label: {
                        Image(systemName: isRevealed ? "eye.slash.fill" : "eye.fill")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)
                    }
                }
            }
            .padding()
            .background(AJTheme.softWhite)
            .cornerRadius(AJTheme.cornerRadiusSmall)
            .overlay(
                RoundedRectangle(cornerRadius: AJTheme.cornerRadiusSmall)
                    .stroke(AJTheme.sage.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Name Entry Step

struct NameEntryStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: AJTheme.paddingXLarge) {
            Spacer()

            VStack(spacing: AJTheme.paddingMedium) {
                Image(systemName: "person.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(AJTheme.sage)
                    .accessibilityHidden(true)

                Text("What should we call you?")
                    .font(AJTheme.headlineFont)
                    .foregroundColor(AJTheme.primaryText)

                Text("Your journey will be personally crafted for you.")
                    .font(AJTheme.bodyFont)
                    .foregroundStyle(AJTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }

            TextField("Your name", text: $viewModel.userName)
                .font(.system(.title3, design: .serif))
                .multilineTextAlignment(.center)
                .padding()
                .background(AJTheme.softWhite)
                .cornerRadius(AJTheme.cornerRadiusSmall)
                .overlay(
                    RoundedRectangle(cornerRadius: AJTheme.cornerRadiusSmall)
                        .stroke(AJTheme.sage.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 48)
                .focused($isFocused)
                .onAppear { isFocused = true }

            Spacer()

            HStack {
                Button("Back") { viewModel.previousStep() }
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(AJTheme.secondaryText)

                Spacer()

                Button {
                    isFocused = false
                    viewModel.nextStep()
                } label: {
                    HStack(spacing: 6) {
                        Text("Next")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(.body, design: .serif, weight: .semibold))
                    .foregroundColor(AJTheme.sage)
                }
                .disabled(viewModel.userName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, AJTheme.paddingXLarge)
            .padding(.bottom, 48)
        }
        .padding()
        .onSubmit {
            guard !viewModel.userName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            isFocused = false
            viewModel.nextStep()
        }
    }
}

// MARK: - Maturity Step

struct MaturityStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: AJTheme.paddingLarge) {
            Spacer()

            VStack(spacing: 12) {
                Text("Where are you in your walk with God?")
                    .font(AJTheme.headlineFont)
                    .foregroundColor(AJTheme.primaryText)
                    .multilineTextAlignment(.center)

                Text("No wrong answers — this helps us meet you where you are.")
                    .font(AJTheme.bodyFont)
                    .foregroundStyle(AJTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                ForEach(SpiritualMaturity.allCases, id: \.self) { maturity in
                    Button {
                        viewModel.selectedMaturity = maturity
                    } label: {
                        HStack {
                            Text(maturity.rawValue)
                                .font(.system(.body, design: .serif))
                                .foregroundColor(AJTheme.primaryText)
                            Spacer()
                            if viewModel.selectedMaturity == maturity {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AJTheme.sage)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: AJTheme.cornerRadiusSmall)
                                .fill(viewModel.selectedMaturity == maturity ? AJTheme.sage.opacity(0.1) : AJTheme.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AJTheme.cornerRadiusSmall)
                                .stroke(viewModel.selectedMaturity == maturity ? AJTheme.sage : .clear, lineWidth: 1)
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
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(AJTheme.secondaryText)
                Spacer()
                Button {
                    viewModel.nextStep()
                } label: {
                    HStack(spacing: 6) {
                        Text("Next")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(.body, design: .serif, weight: .semibold))
                    .foregroundColor(AJTheme.sage)
                }
            }
            .padding(.horizontal, AJTheme.paddingXLarge)
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
        VStack(spacing: AJTheme.paddingLarge) {
            if let question = viewModel.currentQuestion {
                HStack {
                    Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.questions.count)")
                        .font(AJTheme.captionFont)
                        .foregroundStyle(AJTheme.secondaryText)
                    Spacer()
                }
                .padding(.horizontal)

                ProgressView(value: viewModel.quizProgress)
                    .tint(AJTheme.sage)
                    .padding(.horizontal)

                Spacer()

                VStack(spacing: 6) {
                    Text(question.text)
                        .font(.system(.title3, design: .serif, weight: .bold))
                        .foregroundColor(AJTheme.primaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)

                    if case .slider = question.type {
                        Text("Slide to where you feel you are right now.")
                            .font(AJTheme.bodyFont)
                            .foregroundStyle(AJTheme.secondaryText)
                    }
                }

                switch question.type {
                case .multipleChoice:
                    VStack(spacing: 10) {
                        ForEach(question.options, id: \.self) { option in
                            Button {
                                viewModel.answerQuestion(option)
                            } label: {
                                Text(option)
                                    .font(.system(.body, design: .serif))
                                    .foregroundColor(AJTheme.primaryText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(AJTheme.cardBackground)
                                    .cornerRadius(AJTheme.cornerRadiusSmall)
                                    .shadow(color: AJTheme.cardShadow, radius: 4, x: 0, y: 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)

                case .slider(let min, let max, let step):
                    VStack(spacing: 16) {
                        Text("\(Int(sliderValue))")
                            .font(.system(size: 48, weight: .bold, design: .serif))
                            .foregroundStyle(AJTheme.sage)
                            .contentTransition(.numericText())

                        Slider(value: $sliderValue, in: min...max, step: step)
                            .tint(AJTheme.sage)
                            .padding(.horizontal, AJTheme.paddingXLarge)

                        HStack {
                            Text("Not much")
                                .font(AJTheme.captionFont)
                                .foregroundStyle(AJTheme.secondaryText)
                            Spacer()
                            Text("A lot")
                                .font(AJTheme.captionFont)
                                .foregroundStyle(AJTheme.secondaryText)
                        }
                        .padding(.horizontal, AJTheme.paddingXLarge)

                        Button {
                            viewModel.answerQuestion("\(Int(sliderValue))", numericValue: sliderValue)
                        } label: {
                            Text("Continue")
                        }
                        .buttonStyle(AJPrimaryButtonStyle())
                        .padding(.horizontal, 80)
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
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(AJTheme.secondaryText)
                    Spacer()
                }
                .padding(.horizontal, AJTheme.paddingXLarge)
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
                            .font(.system(.body, design: .serif))
                            .foregroundColor(AJTheme.primaryText)
                        Spacer()
                        Image(systemName: selected.contains(option) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selected.contains(option) ? AJTheme.sage : AJTheme.secondaryText)
                            .accessibilityHidden(true)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AJTheme.cornerRadiusSmall)
                            .fill(selected.contains(option) ? AJTheme.sage.opacity(0.1) : AJTheme.cardBackground)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected.contains(option) ? .isSelected : [])
            }

            Button("Continue") {
                onComplete(Array(selected))
            }
            .buttonStyle(AJPrimaryButtonStyle())
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
        VStack(spacing: AJTheme.paddingLarge) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AJTheme.gold)
                    .accessibilityHidden(true)

                Text("Choose Your Bible Translation")
                    .font(AJTheme.headlineFont)
                    .foregroundColor(AJTheme.primaryText)

                Text("You can change this anytime.")
                    .font(AJTheme.bodyFont)
                    .foregroundStyle(AJTheme.secondaryText)
            }

            VStack(spacing: 10) {
                ForEach(BibleTranslation.allCases, id: \.self) { translation in
                    Button {
                        viewModel.selectedTranslation = translation
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(translation.rawValue)
                                    .font(.system(.headline, design: .serif))
                                    .foregroundColor(AJTheme.primaryText)
                                Text(translation.fullName)
                                    .font(AJTheme.captionFont)
                                    .foregroundStyle(AJTheme.secondaryText)
                            }
                            Spacer()
                            if viewModel.selectedTranslation == translation {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AJTheme.sage)
                                    .accessibilityHidden(true)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: AJTheme.cornerRadiusSmall)
                                .fill(viewModel.selectedTranslation == translation ? AJTheme.sage.opacity(0.1) : AJTheme.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AJTheme.cornerRadiusSmall)
                                .stroke(viewModel.selectedTranslation == translation ? AJTheme.sage : .clear, lineWidth: 1)
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
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(AJTheme.secondaryText)
                Spacer()
                Button {
                    viewModel.nextStep()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Generate My Journey")
                    }
                }
                .buttonStyle(AJPrimaryButtonStyle())
                .frame(width: 220)
            }
            .padding(.horizontal, AJTheme.paddingXLarge)
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
    @State private var messageIndex = 0

    private let messages = [
        "Reading your heart...",
        "Selecting Scripture for your season...",
        "Building your 40-day path...",
        "Adding reflection prompts...",
        "Almost there..."
    ]

    var body: some View {
        VStack(spacing: AJTheme.paddingXLarge) {
            Spacer()

            if let errorMessage = viewModel.generationError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AJTheme.warning)
                    .accessibilityHidden(true)

                Text("Something went wrong")
                    .font(AJTheme.headlineFont)
                    .foregroundColor(AJTheme.primaryText)

                Text(errorMessage)
                    .font(AJTheme.bodyFont)
                    .foregroundStyle(AJTheme.secondaryText)
                    .multilineTextAlignment(.center)

                Button("Try Again") {
                    viewModel.generationError = nil
                    hasStarted = false
                }
                .buttonStyle(AJPrimaryButtonStyle())
                .padding(.horizontal, 80)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 64))
                    .foregroundStyle(AJTheme.gold)
                    .symbolEffect(.variableColor)
                    .accessibilityHidden(true)

                Text("Crafting Your Journey")
                    .font(AJTheme.headlineFont)
                    .foregroundColor(AJTheme.primaryText)

                Text(messages[messageIndex])
                    .font(AJTheme.bodyFont)
                    .foregroundStyle(AJTheme.secondaryText)
                    .contentTransition(.opacity)
                    .animation(.easeInOut, value: messageIndex)

                ProgressView()
                    .tint(AJTheme.sage)
                    .scaleEffect(1.2)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            viewModel.generateJourney(context: modelContext)

            for i in 1..<messages.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.6) {
                    withAnimation { messageIndex = i }
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
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
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AJTheme.gold.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(appeared ? 1 : 0.3)

                Image(systemName: "sunrise.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AJTheme.gold)
                    .symbolEffect(.bounce, value: appeared)
            }
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                if let name = viewModel.userName.trimmingCharacters(in: .whitespaces).components(separatedBy: " ").first,
                   !name.isEmpty {
                    Text("\(name), you're all set!")
                        .font(AJTheme.titleFont)
                        .foregroundColor(AJTheme.primaryText)
                } else {
                    Text("You're all set!")
                        .font(AJTheme.titleFont)
                        .foregroundColor(AJTheme.primaryText)
                }

                if let journey = viewModel.generatedJourney {
                    Text(journey.title)
                        .font(.system(.title3, design: .serif))
                        .foregroundStyle(AJTheme.sage)

                    Text(journey.subtitle)
                        .font(AJTheme.bodyFont)
                        .foregroundStyle(AJTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }

            VStack(spacing: 8) {
                Label("40 days of personalized devotionals", systemImage: "book.fill")
                Label("Daily Scripture, prayer & reflection", systemImage: "text.quote")
                Label("Track your growth every step of the way", systemImage: "chart.line.uptrend.xyaxis")
            }
            .font(.system(.subheadline, design: .serif))
            .foregroundStyle(AJTheme.secondaryText)

            Spacer()

            Button {
                onStart()
            } label: {
                Text("Start Day 1")
            }
            .buttonStyle(AJPrimaryButtonStyle())
            .padding(.horizontal, AJTheme.paddingXLarge)
            .padding(.bottom, 48)
        }
        .padding()
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                appeared = true
            }
        }
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
