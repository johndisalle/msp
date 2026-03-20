// MainTabView.swift
// FaithForge
//
// Bottom tab bar with Home, Quests, and Progress tabs.

import SwiftUI
import SwiftData

struct MainTabView: View {
    let profile: UserProfile
    @Environment(\.modelContext) private var modelContext

    @State private var questManager: QuestManager?
    @State private var xpManager: XPManager?
    @State private var selectedTab: Tab = .home

    enum Tab: String {
        case home     = "Home"
        case quests   = "Quests"
        case progress = "Progress"
    }

    var body: some View {
        Group {
            if let questManager, let xpManager {
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

                    SwiftUI.Tab("Progress", systemImage: "chart.bar.fill", value: Tab.progress) {
                        ProgressView(
                            profile: profile,
                            xpManager: xpManager
                        )
                    }
                }
                .tint(Color("FaithBlue"))
            } else {
                ProgressLoadingView()
            }
        }
        .onAppear {
            if questManager == nil {
                questManager = QuestManager(modelContext: modelContext)
            }
            if xpManager == nil {
                xpManager = XPManager(modelContext: modelContext)
            }
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
