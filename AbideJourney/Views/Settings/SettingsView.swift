import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
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

                        if profile.notificationsEnabled {
                            DatePicker(
                                "Morning Reminder",
                                selection: Bindable(profile).notificationMorningTime,
                                displayedComponents: .hourAndMinute
                            )

                            DatePicker(
                                "Evening Check-In",
                                selection: Bindable(profile).notificationEveningTime,
                                displayedComponents: .hourAndMinute
                            )
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

                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }

                    Link(destination: URL(string: "https://example.com/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text")
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
}

#Preview {
    SettingsView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
