import SwiftUI
import SwiftData
import AuthenticationServices

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var profiles: [UserProfile]
    @Query private var journeys: [Journey]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showingPremiumSheet = false
    @State private var showingNewJourneySheet = false
    @State private var showingAbandonConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var showingCouplesSheet = false
    @State private var showingDynamicSheet = false
    @State private var showingGiftSheet = false
    @State private var showingReferralSheet = false
    @State private var showingWelcomeGuide = false
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("appColorTheme") private var appColorTheme: AppColorTheme = .classic

    private var profile: UserProfile? { profiles.first }
    private var completedJourneys: [Journey] {
        journeys.filter { $0.isCompleted }.sorted { $0.startDate > $1.startDate }
    }
    private var notificationTimeConflict: Bool {
        guard let profile, profile.notificationsEnabled else { return false }
        let cal = Calendar.current
        let morning = cal.dateComponents([.hour, .minute], from: profile.notificationMorningTime)
        let evening = cal.dateComponents([.hour, .minute], from: profile.notificationEveningTime)
        let morningMinutes = (morning.hour ?? 0) * 60 + (morning.minute ?? 0)
        let eveningMinutes = (evening.hour ?? 0) * 60 + (evening.minute ?? 0)
        return morningMinutes >= eveningMinutes
    }

    var body: some View {
        NavigationStack {
            List {
                // Profile section
                if let profile = profile {
                    Section("Profile") {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                .foregroundStyle(.accent)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading) {
                                Text(profile.name)
                                    .font(.headline)
                                Text(profile.spiritualMaturity.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Account
                    Section("Account") {
                        if AuthService.shared.isSignedIn {
                            HStack {
                                Image(systemName: AuthService.shared.authMethod == .apple ? "apple.logo" : "envelope.fill")
                                    .foregroundStyle(AuthService.shared.authMethod == .apple ? .primary : AJTheme.sage)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(AuthService.shared.authMethod == .apple ? "Signed in with Apple" : "Signed in with Email")
                                        .font(.subheadline)
                                    if let name = AuthService.shared.userFullName {
                                        Text(name)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if let email = AuthService.shared.userEmail {
                                        Text(email)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }

                            Button(role: .destructive) {
                                AuthService.shared.signOut()
                            } label: {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } else {
                            SignInWithAppleButton(.signIn, onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            }, onCompletion: { result in
                                handleSignIn(result, profile: profile)
                            })
                            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                            .frame(height: 44)
                        }
                    }

                    // Bible Translation
                    Section("Bible Translation") {
                        Picker("Translation", selection: Bindable(profile).preferredTranslation) {
                            ForEach(BibleTranslation.allCases, id: \.self) { translation in
                                Text("\(translation.rawValue) - \(translation.fullName)")
                                    .tag(translation)
                            }
                        }
                    }

                    // Notifications
                    Section("Notifications") {
                        Toggle("Enable Notifications", isOn: Bindable(profile).notificationsEnabled)
                            .onChange(of: profile.notificationsEnabled) { _, _ in
                                rescheduleNotifications(for: profile)
                            }

                        if profile.notificationsEnabled {
                            DatePicker(
                                "Morning Reminder",
                                selection: Bindable(profile).notificationMorningTime,
                                displayedComponents: .hourAndMinute
                            )
                            .onChange(of: profile.notificationMorningTime) { _, _ in
                                rescheduleNotifications(for: profile)
                            }

                            DatePicker(
                                "Evening Check-In",
                                selection: Bindable(profile).notificationEveningTime,
                                displayedComponents: .hourAndMinute
                            )
                            .onChange(of: profile.notificationEveningTime) { _, _ in
                                rescheduleNotifications(for: profile)
                            }

                            if notificationTimeConflict {
                                Label("Morning reminder should be earlier than the evening check-in.", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }

                // Appearance
                Section("Appearance") {
                    Picker("Mode", selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Color Theme")
                            .font(.subheadline)
                            .foregroundStyle(AJTheme.secondaryText)

                        HStack(spacing: 12) {
                            ForEach(AppColorTheme.allCases, id: \.self) { theme in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        appColorTheme = theme
                                    }
                                } label: {
                                    VStack(spacing: 6) {
                                        ZStack {
                                            Circle()
                                                .fill(theme.primaryAccent)
                                                .frame(width: 36, height: 36)
                                            Circle()
                                                .fill(theme.secondaryAccent)
                                                .frame(width: 16, height: 16)
                                                .offset(x: 8, y: 8)
                                        }
                                        .overlay(
                                            Circle()
                                                .stroke(appColorTheme == theme ? theme.primaryAccent : .clear, lineWidth: 2)
                                                .frame(width: 44, height: 44)
                                        )

                                        Text(theme.label)
                                            .font(.caption2)
                                            .foregroundStyle(appColorTheme == theme ? AJTheme.primaryText : AJTheme.secondaryText)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 4)
                }

                // Journey
                Section("Journey") {
                    if let activeJourney = journeys.first(where: { $0.isActive && !$0.isCompleted }) {
                        HStack(spacing: 12) {
                            Image(systemName: activeJourney.theme.icon)
                                .foregroundStyle(Color(activeJourney.theme.color, default: .accentColor))
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(activeJourney.title)
                                    .font(.subheadline.bold())
                                Text("Day \(activeJourney.currentDay)/\(activeJourney.totalDays)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            ProgressView(value: activeJourney.progress)
                                .tint(.accent)
                                .frame(width: 60)
                        }

                        Button(role: .destructive) {
                            showingAbandonConfirmation = true
                        } label: {
                            Label("Abandon Journey", systemImage: "xmark.circle")
                        }
                        .confirmationDialog(
                            "Abandon \"\(activeJourney.title)\"?",
                            isPresented: $showingAbandonConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button("Abandon Journey", role: .destructive) {
                                activeJourney.isActive = false
                                activeJourney.isCompleted = true
                                try? modelContext.save()
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("Your progress will be saved in Past Journeys, but you won't be able to resume it.")
                        }
                    }

                    Button {
                        showingNewJourneySheet = true
                    } label: {
                        Label("Start New Journey", systemImage: "plus.circle")
                    }

                    if profile?.isPremium == true {
                        Button {
                            showingDynamicSheet = true
                        } label: {
                            Label("Create Custom Journey", systemImage: "wand.and.stars")
                        }

                        Button {
                            showingCouplesSheet = true
                        } label: {
                            Label("Couples Journey", systemImage: "heart.circle.fill")
                                .foregroundStyle(.pink)
                        }
                    }
                }

                // Past journeys
                if !completedJourneys.isEmpty {
                    Section("Past Journeys") {
                        ForEach(completedJourneys) { journey in
                            HStack(spacing: 12) {
                                Image(systemName: journey.theme.icon)
                                    .foregroundStyle(Color(journey.theme.color, default: .accentColor))
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(journey.title)
                                        .font(.subheadline.bold())
                                    Text("Day \(journey.currentDay)/\(journey.totalDays) — \(journey.startDate, format: .dateTime.month().year())")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if journey.currentDay >= journey.totalDays {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else {
                                    Text("Archived")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                // Accountability (Premium)
                if profile?.isPremium == true {
                    Section("Accountability") {
                        NavigationLink {
                            AccountabilityView()
                        } label: {
                            Label("Accountability Partners", systemImage: "person.2.fill")
                        }
                    }
                }

                // Premium
                Section("Premium") {
                    if profile?.isPremium == true {
                        HStack {
                            Label("Premium Active", systemImage: "crown.fill")
                                .foregroundStyle(.orange)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .accessibilityHidden(true)
                        }

                        Button {
                            showingGiftSheet = true
                        } label: {
                            Label("Gift a Journey", systemImage: "gift.fill")
                        }

                        Button {
                            showingReferralSheet = true
                        } label: {
                            HStack {
                                Label("Refer a Friend", systemImage: "person.badge.plus")
                                Spacer()
                                if ReferralService.shared.referralCount > 0 {
                                    Text("\(ReferralService.shared.referralCount) referred")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        NavigationLink {
                            FaithReportView()
                        } label: {
                            Label("Annual Faith Report", systemImage: "sparkles.rectangle.stack.fill")
                        }
                    } else {
                        Button {
                            showingPremiumSheet = true
                        } label: {
                            HStack {
                                Label("Upgrade to Premium", systemImage: "crown")
                                Spacer()
                                Text("$4.99/mo")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button {
                            showingReferralSheet = true
                        } label: {
                            Label("Invite Friends, Get Free Premium", systemImage: "person.badge.plus")
                                .foregroundStyle(AJTheme.sage)
                        }

                        Button {
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                windowScene.presentOfferCodeRedeemSheet()
                            }
                        } label: {
                            Label("Redeem Offer Code", systemImage: "ticket")
                        }
                    }
                }

                // About
                Section("About") {
                    Button {
                        showingWelcomeGuide = true
                    } label: {
                        Label("Show Welcome Guide", systemImage: "questionmark.circle.fill")
                    }

                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    if let privacyURL = URL(string: "https://johndisalle.github.io/msp/privacy.html") {
                        Link(destination: privacyURL) {
                            Label("Privacy Policy", systemImage: "hand.raised")
                        }
                    }

                    if let termsURL = URL(string: "https://johndisalle.github.io/msp/terms.html") {
                        Link(destination: termsURL) {
                            Label("Terms of Service", systemImage: "doc.text")
                        }
                    }

                    if let supportURL = URL(string: "https://johndisalle.github.io/msp/support.html") {
                        Link(destination: supportURL) {
                            Label("Customer Support", systemImage: "questionmark.circle")
                        }
                    }
                }

                // Account management
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete All Data & Reset", systemImage: "trash")
                    }
                    .confirmationDialog(
                        "Delete all your data?",
                        isPresented: $showingDeleteConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Delete Everything", role: .destructive) {
                            deleteAllData()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will permanently delete your profile, all journeys, journal entries, prayer sessions, and accountability partners. This cannot be undone.")
                    }
                } footer: {
                    Text("Removes all app data and returns to the welcome screen.")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPremiumSheet) {
                PremiumPaywallView()
            }
            .sheet(isPresented: $showingNewJourneySheet) {
                NewJourneyView()
            }
            .sheet(isPresented: $showingCouplesSheet) {
                CouplesJourneyView()
            }
            .sheet(isPresented: $showingDynamicSheet) {
                DynamicJourneyView()
            }
            .sheet(isPresented: $showingGiftSheet) {
                GiftJourneyView()
            }
            .sheet(isPresented: $showingReferralSheet) {
                ReferralView(userName: profile?.name ?? "Friend")
            }
            .sheet(isPresented: $showingWelcomeGuide) {
                WelcomeGuideView {
                    showingWelcomeGuide = false
                }
            }
        }
    }
    private func deleteAllData() {
        // Cancel notifications
        NotificationService.shared.cancelAllNotifications()

        // Delete all profiles (cascade will delete journeys, days, entries, partners, etc.)
        for profile in profiles {
            modelContext.delete(profile)
        }
        // Delete any orphaned journeys just in case
        for journey in journeys {
            modelContext.delete(journey)
        }
        try? modelContext.save()

        // Reset onboarding flag to return to welcome screen
        hasCompletedOnboarding = false
    }

    private func handleSignIn(_ result: Result<ASAuthorization, Error>, profile: UserProfile) {
        do {
            try AuthService.shared.handleAuthorization(result)
            profile.appleUserID = AuthService.shared.appleUserID
            if let email = AuthService.shared.userEmail {
                profile.email = email
            }
            if let fullName = AuthService.shared.userFullName, !fullName.isEmpty {
                profile.name = fullName
            }
            try? modelContext.save()
        } catch {
            // User cancelled or auth failed — no action needed
        }
    }

    private func rescheduleNotifications(for profile: UserProfile) {
        NotificationService.shared.cancelAllNotifications()
        guard profile.notificationsEnabled,
              let journey = journeys.first(where: { $0.isActive && !$0.isCompleted }),
              let currentDay = (journey.days ?? [])
                .sorted(by: { $0.dayNumber < $1.dayNumber })
                .first(where: { !$0.isCompleted && $0.isUnlocked })
                ?? (journey.days ?? [])
                .sorted(by: { $0.dayNumber < $1.dayNumber })
                .first(where: { !$0.isCompleted })
        else { return }

        NotificationService.shared.scheduleMorningReminder(
            at: profile.notificationMorningTime,
            dayNumber: currentDay.dayNumber,
            verseSnippet: String(currentDay.scriptureText.prefix(60))
        )
        NotificationService.shared.scheduleEveningCheckIn(
            at: profile.notificationEveningTime,
            dayNumber: currentDay.dayNumber
        )
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
