// RootView.swift
// FaithForge
//
// Root navigation: shows onboarding if not completed, otherwise main tab bar.

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        Group {
            if let profile, profile.onboardingCompleted {
                MainTabView(profile: profile)
            } else {
                OnboardingFlowView()
            }
        }
        .onAppear {
            seedBadgesIfNeeded()
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
}

#Preview {
    RootView()
        .modelContainer(for: [UserProfile.self, DailyQuest.self, Badge.self, FaithRingProgress.self, LeaderboardEntry.self, FriendConnection.self, CommunityChallenge.self], inMemory: true)
        .environment(FirebaseAuthStub())
}
