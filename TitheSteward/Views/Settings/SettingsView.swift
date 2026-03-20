import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingPaywall = false
    @State private var showingDebtTools = false
    @State private var showingDevotionals = false
    @State private var showingCounselor = false
    @State private var showingBadges = false
    @State private var showingReports = false
    @State private var showingTaxSummary = false

    var body: some View {
        NavigationStack {
            List {
                // Premium Section
                Section {
                    Button {
                        showingPaywall = true
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(Color("AccentGold"))
                            VStack(alignment: .leading) {
                                Text("Tithe Steward Premium")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(appState.isPremium ? "Active" : "Unlock all features")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if !appState.isPremium {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Tools Section
                Section("Tools") {
                    NavigationLink {
                        DevotionalFeedView()
                    } label: {
                        Label("Devotional Library", systemImage: "book.fill")
                    }

                    NavigationLink {
                        DebtDashboardView()
                    } label: {
                        Label("Debt Freedom Tools", systemImage: "lock.open.fill")
                    }

                    Button {
                        if appState.isPremium {
                            showingCounselor = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        PremiumToolRow(label: "AI Counselor", icon: "bubble.left.and.bubble.right.fill", isPremium: appState.isPremium)
                    }

                    Button {
                        if appState.isPremium {
                            showingBadges = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        PremiumToolRow(label: "Generosity Badges", icon: "trophy.fill", isPremium: appState.isPremium)
                    }

                    Button {
                        if appState.isPremium {
                            showingReports = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        PremiumToolRow(label: "Advanced Reports", icon: "chart.bar.fill", isPremium: appState.isPremium)
                    }

                    Button {
                        if appState.isPremium {
                            showingTaxSummary = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        PremiumToolRow(label: "Tax Summary & Export", icon: "doc.text.fill", isPremium: appState.isPremium)
                    }
                }

                Section("Community") {
                    NavigationLink {
                        SharingView()
                    } label: {
                        Label("Share & Invite", systemImage: "square.and.arrow.up")
                    }
                }

                // Notifications
                Section("Notifications") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Reminders & Alerts", systemImage: "bell.fill")
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://tithesteward.app/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }

                    Link(destination: URL(string: "https://tithesteward.app/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text.fill")
                    }
                }

                // Faith Commitment
                Section {
                    VStack(spacing: 8) {
                        Text("We tithe 10% of all profits")
                            .font(.subheadline.bold())
                            .foregroundColor(Color("AccentGold"))
                        Text("Because we believe in practicing what we preach.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color("AccentGold").opacity(0.1))
                }

                // Sign Out
                Section {
                    Button(role: .destructive) {
                        appState.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("More")
            .sheet(isPresented: $showingPaywall) {
                PremiumPaywallView()
            }
            .sheet(isPresented: $showingCounselor) {
                NavigationStack {
                    AICounselorChatView()
                }
            }
            .sheet(isPresented: $showingBadges) {
                NavigationStack {
                    BadgeGalleryView()
                }
            }
            .sheet(isPresented: $showingReports) {
                NavigationStack {
                    AdvancedReportsView()
                }
            }
            .sheet(isPresented: $showingTaxSummary) {
                NavigationStack {
                    TaxSummaryView()
                }
            }
        }
    }
}

struct NotificationSettingsView: View {
    @State private var titheReminders = true
    @State private var devotionalReminder = true
    @State private var streakAlerts = true
    @State private var reminderTime = Date()

    var body: some View {
        Form {
            Section("Giving Reminders") {
                Toggle("Payday tithe reminders", isOn: $titheReminders)
                Toggle("Generosity streak alerts", isOn: $streakAlerts)
            }

            Section("Devotional") {
                Toggle("Daily devotional reminder", isOn: $devotionalReminder)
                if devotionalReminder {
                    DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }
            }

            Section {
                Text("\"Be faithful in small things, because it is in them that your strength lies.\"")
                    .font(.callout.italic())
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Notifications")
    }
}

struct PremiumToolRow: View {
    let label: String
    let icon: String
    let isPremium: Bool

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundColor(.primary)
            Spacer()
            if !isPremium {
                Text("Premium")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color("AccentGold"))
                    .clipShape(Capsule())
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
