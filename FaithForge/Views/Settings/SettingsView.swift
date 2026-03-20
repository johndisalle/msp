// SettingsView.swift
// FaithForge
//
// App settings: profile, AI quests, account, and about.

import SwiftUI

struct SettingsView: View {
    @Bindable var profile: UserProfile
    @Bindable var aiService: AIQuestService
    @Bindable var authService: FirebaseAuthStub

    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                // Profile
                Section("Profile") {
                    HStack(spacing: 14) {
                        Image(systemName: profile.level.icon)
                            .font(.title2)
                            .foregroundStyle(Color("FaithGold"))
                            .frame(width: 44, height: 44)
                            .background(Color("FaithGold").opacity(0.15))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.displayName)
                                .font(.headline)
                            Text("\(profile.level.rawValue) \u{2022} \(profile.totalXP) XP")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Picker("Daily Goal", selection: Binding(
                        get: { profile.dailyGoal },
                        set: { profile.dailyGoal = $0 }
                    )) {
                        ForEach(DailyGoalIntensity.allCases, id: \.rawValue) { intensity in
                            Text("\(intensity.rawValue) (\(intensity.subtitle))")
                                .tag(intensity)
                        }
                    }
                }

                // AI Quests
                Section {
                    NavigationLink {
                        AIQuestSettingsView(aiService: aiService, profile: profile)
                    } label: {
                        HStack {
                            Label("AI Quest Generation", systemImage: "sparkles")
                            Spacer()
                            Text(aiService.isEnabled ? "On" : "Off")
                                .font(.subheadline)
                                .foregroundStyle(aiService.isEnabled ? Color("FaithGreen") : .secondary)
                        }
                    }
                } header: {
                    Text("AI Features")
                } footer: {
                    Text("Personalize your daily quests with AI based on your faith journey.")
                }

                // Sound & Haptics
                Section("Sound & Haptics") {
                    Toggle(isOn: Binding(
                        get: { SoundManager.shared.isEnabled },
                        set: { SoundManager.shared.isEnabled = $0 }
                    )) {
                        Label("Sound Effects", systemImage: "speaker.wave.2.fill")
                    }

                    NavigationLink {
                        NotificationSettingsView(profile: profile)
                    } label: {
                        Label("Notifications", systemImage: "bell.badge.fill")
                    }
                }

                // Account
                Section("Account") {
                    HStack {
                        Label("Signed in as", systemImage: "person.circle")
                        Spacer()
                        Text(authService.displayName ?? "Guest")
                            .foregroundStyle(.secondary)
                    }

                    if authService.isSignedIn {
                        Button(role: .destructive) {
                            authService.signOut()
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0 (MVP)")
                            .foregroundStyle(.secondary)
                    }

                    Label("FaithForge — Duolingo for Discipleship", systemImage: "cross.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Premium
                Section {
                    if PremiumManager.shared.isPremium {
                        HStack {
                            Label("FaithForge Premium", systemImage: "crown.fill")
                                .foregroundStyle(Color("FaithGold"))
                            Spacer()
                            Text("Active")
                                .font(.caption)
                                .foregroundStyle(Color("FaithGreen"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color("FaithGreen").opacity(0.15))
                                .clipShape(Capsule())
                        }
                    } else {
                        Button {
                            showingPaywall = true
                        } label: {
                            HStack {
                                Label("FaithForge Premium", systemImage: "crown.fill")
                                    .foregroundStyle(Color("FaithGold"))
                                Spacer()
                                Text("Upgrade")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color("FaithGold"))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                } footer: {
                    Text("Unlock AI quests, custom themes, advanced stats, and ad-free experience.")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPaywall) {
                PremiumPaywallView()
            }
        }
    }
}
