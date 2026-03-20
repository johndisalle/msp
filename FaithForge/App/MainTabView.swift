// MainTabView.swift
// FaithForge
//
// Bottom tab bar with Home, Quests, Community, Progress, and Settings tabs.

import SwiftUI
import SwiftData

struct MainTabView: View {
    let profile: UserProfile
    @Environment(\.modelContext) private var modelContext
    @Environment(FirebaseAuthStub.self) private var authService

    @State private var questManager: QuestManager?
    @State private var xpManager: XPManager?
    @State private var leaderboardService: LeaderboardService?
    @State private var friendService: FriendService?
    @State private var challengeService: ChallengeService?
    @State private var aiQuestService: AIQuestService?
    @State private var selectedTab: Tab = .home

    enum Tab: String {
        case home      = "Home"
        case quests    = "Quests"
        case community = "Community"
        case progress  = "Progress"
        case settings  = "Settings"
    }

    var body: some View {
        Group {
            if let questManager, let xpManager,
               let leaderboardService, let friendService,
               let challengeService, let aiQuestService {
                TabView(selection: $selectedTab) {
                    SwiftUI.Tab("Home", systemImage: "house.fill", value: Tab.home) {
                        HomeDashboardView(
                            profile: profile,
                            questManager: questManager,
                            xpManager: xpManager
                        )
                    }

                    SwiftUI.Tab("Quests", systemImage: "list.bullet.clipboard.fill", value: Tab.quests) {
                        QuestsListView(
                            profile: profile,
                            questManager: questManager,
                            xpManager: xpManager
                        )
                    }

                    SwiftUI.Tab("Community", systemImage: "person.3.fill", value: Tab.community) {
                        SocialTabView(
                            profile: profile,
                            leaderboardService: leaderboardService,
                            friendService: friendService,
                            challengeService: challengeService
                        )
                    }

                    SwiftUI.Tab("Progress", systemImage: "chart.bar.fill", value: Tab.progress) {
                        ProgressView(
                            profile: profile,
                            xpManager: xpManager
                        )
                    }

                    SwiftUI.Tab("Settings", systemImage: "gearshape.fill", value: Tab.settings) {
                        SettingsView(
                            profile: profile,
                            aiService: aiQuestService,
                            authService: authService
                        )
                    }
                }
                .tint(Color("FaithBlue"))
            } else {
                ProgressLoadingView()
            }
        }
        .onAppear {
            initializeServices()
        }
    }

    private func initializeServices() {
        if questManager == nil {
            questManager = QuestManager(modelContext: modelContext)
        }
        if xpManager == nil {
            xpManager = XPManager(modelContext: modelContext)
        }
        if leaderboardService == nil {
            leaderboardService = LeaderboardService(modelContext: modelContext)
        }
        if friendService == nil {
            friendService = FriendService(modelContext: modelContext)
        }
        if challengeService == nil {
            challengeService = ChallengeService(modelContext: modelContext)
        }
        if aiQuestService == nil {
            aiQuestService = AIQuestService(modelContext: modelContext)
        }

        // Sync local profile to leaderboard
        if let leaderboardService {
            leaderboardService.syncLocalProfile(
                profile,
                userID: authService.userID ?? "local-\(profile.id)"
            )
        }
    }
}

/// Simple loading spinner while managers initialize.
private struct ProgressLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            SwiftUI.ProgressView()
                .controlSize(.large)
            Text("Preparing your journey...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
