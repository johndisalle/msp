// RootView.swift
// FaithForge
//
// Root navigation: shows onboarding if not completed, otherwise main tab bar.

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var showLaunchScreen = true

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            Group {
                if let profile, profile.onboardingCompleted {
                    MainTabView(profile: profile)
                } else {
                    OnboardingFlowView()
                }
            }

            // Launch screen overlay
            if showLaunchScreen {
                LaunchScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            seedBadgesIfNeeded()
            scheduleNotifications()
            // Dismiss launch screen after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showLaunchScreen = false
                }
            }
        }
    }

    /// Seed default badges on first launch.
    private func seedBadgesIfNeeded() {
        let descriptor = FetchDescriptor<Badge>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        for badge in Badge.seedBadges {
            modelContext.insert(badge)
        }
        try? modelContext.save()
    }

    /// Set up recurring notifications after onboarding.
    private func scheduleNotifications() {
        guard let profile, profile.onboardingCompleted else { return }
        NotificationService.shared.scheduleDailyQuestReminder()
        NotificationService.shared.scheduleStreakAtRiskAlert(currentStreak: profile.currentStreak)
        NotificationService.shared.scheduleWeeklySummary(weeklyXP: 0, questsCompleted: 0)
    }
}

#Preview {
    RootView()
        .modelContainer(for: [UserProfile.self, DailyQuest.self, Badge.self, FaithRingProgress.self, LeaderboardEntry.self, FriendConnection.self, CommunityChallenge.self], inMemory: true)
        .environment(FirebaseAuthStub())
}
