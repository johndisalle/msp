// NotificationSettingsView.swift
// FaithForge
//
// Configure notification preferences: reminder time, streak alerts, challenge updates.

import SwiftUI

struct NotificationSettingsView: View {
    @Bindable var profile: UserProfile

    @State private var reminderHour: Int = 8
    @State private var reminderMinute: Int = 0
    @State private var streakAlertsEnabled: Bool = true
    @State private var challengeAlertsEnabled: Bool = true
    @State private var isAuthorized: Bool = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Label("Status", systemImage: "bell.circle")
                    Spacer()
                    Text(isAuthorized ? "Authorized" : "Not Authorized")
                        .foregroundStyle(isAuthorized ? Color("FaithGreen") : .secondary)
                }

                if !isAuthorized {
                    Button("Enable Notifications") {
                        Task {
                            await NotificationService.shared.requestAuthorization()
                            await NotificationService.shared.checkAuthorizationStatus()
                            isAuthorized = NotificationService.shared.isAuthorized
                        }
                    }
                }
            } header: {
                Text("Permission")
            }

            Section {
                Picker("Reminder Hour", selection: $reminderHour) {
                    ForEach(5..<23, id: \.self) { hour in
                        Text(formatHour(hour)).tag(hour)
                    }
                }
                .onChange(of: reminderHour) {
                    reschedule()
                }
            } header: {
                Text("Daily Quest Reminder")
            } footer: {
                Text("Get a daily nudge to complete your quests.")
            }

            Section("Alerts") {
                Toggle(isOn: $streakAlertsEnabled) {
                    Label("Streak-at-Risk Alerts", systemImage: "flame.fill")
                }
                .onChange(of: streakAlertsEnabled) {
                    reschedule()
                }

                Toggle(isOn: $challengeAlertsEnabled) {
                    Label("Challenge Milestones", systemImage: "flag.fill")
                }
            }
        }
        .navigationTitle("Notifications")
        .task {
            await NotificationService.shared.checkAuthorizationStatus()
            isAuthorized = NotificationService.shared.isAuthorized
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    private func reschedule() {
        NotificationService.shared.scheduleDailyQuestReminder(hour: reminderHour)
        if streakAlertsEnabled {
            NotificationService.shared.scheduleStreakAtRiskAlert(currentStreak: profile.currentStreak)
        } else {
            NotificationService.shared.cancelStreakAtRiskAlert()
        }
    }
}
