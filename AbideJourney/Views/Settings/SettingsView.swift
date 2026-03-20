import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var journeys: [Journey]
    @State private var showingPremiumSheet = false
    @State private var showingNewJourneySheet = false

    private var profile: UserProfile? { profiles.first }

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
                        }
                    }
                }

                // Journey
                Section("Journey") {
                    Button {
                        showingNewJourneySheet = true
                    } label: {
                        Label("Start New Journey", systemImage: "plus.circle")
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
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    if let privacyURL = URL(string: "https://abidejourney.com/privacy") {
                        Link(destination: privacyURL) {
                            Label("Privacy Policy", systemImage: "hand.raised")
                        }
                    }

                    if let termsURL = URL(string: "https://abidejourney.com/terms") {
                        Link(destination: termsURL) {
                            Label("Terms of Service", systemImage: "doc.text")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPremiumSheet) {
                PremiumPaywallView()
            }
            .sheet(isPresented: $showingNewJourneySheet) {
                NewJourneyView()
            }
        }
    }
    private func rescheduleNotifications(for profile: UserProfile) {
        NotificationService.shared.cancelAllNotifications()
        guard profile.notificationsEnabled,
              let journey = journeys.first(where: { $0.isActive && !$0.isCompleted }),
              let currentDay = journey.days
                .sorted(by: { $0.dayNumber < $1.dayNumber })
                .first(where: { !$0.isCompleted && $0.isUnlocked })
                ?? journey.days
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
