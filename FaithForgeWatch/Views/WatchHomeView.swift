// WatchHomeView.swift
// FaithForgeWatch
//
// Main watch view: streak display, quick prayer log, and today's quest list.

import SwiftUI
import SwiftData
import FaithForgeShared

struct WatchHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(
        filter: #Predicate<DailyQuest> { !$0.isCompleted },
        sort: [SortDescriptor(\DailyQuest.sortOrder)]
    ) private var pendingQuests: [DailyQuest]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Streak
                    streakSection

                    // Quick Prayer Button
                    quickPrayerButton

                    // Pending Quests
                    if !pendingQuests.isEmpty {
                        questsSection
                    }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("FaithForge")
        }
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
                .font(.title3)

            Text("\(profile?.currentStreak ?? 0)")
                .font(.title2.bold())

            Text("day streak")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Quick Prayer

    private var quickPrayerButton: some View {
        Button {
            logQuickPrayer()
        } label: {
            Label("Log Prayer", systemImage: "hands.sparkles.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
    }

    // MARK: - Quests Section

    private var questsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Quests")
                .font(.headline)
                .foregroundStyle(.primary)

            ForEach(pendingQuests.prefix(3), id: \.id) { quest in
                Button {
                    completeQuest(quest)
                } label: {
                    HStack {
                        Image(systemName: quest.category.icon)
                            .font(.caption)
                        Text(quest.title)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Text("+\(quest.xpReward)")
                            .font(.caption2.bold())
                            .foregroundStyle(.yellow)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Actions

    private func logQuickPrayer() {
        guard let profile else { return }
        // Award a flat 20 XP for a quick prayer log
        profile.totalXP += 20
        profile.lastCompletionDate = Date()
        try? modelContext.save()
    }

    private func completeQuest(_ quest: DailyQuest) {
        guard let profile, !quest.isCompleted else { return }
        quest.isCompleted = true
        quest.completedDate = Date()
        profile.totalXP += quest.xpReward
        profile.lastCompletionDate = Date()
        try? modelContext.save()
    }
}
