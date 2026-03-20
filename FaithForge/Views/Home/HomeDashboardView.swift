// HomeDashboardView.swift
// FaithForge
//
// Main dashboard: streak flame, Faith Rings, daily quests, verse of the day.

import SwiftUI

struct HomeDashboardView: View {
    @Bindable var profile: UserProfile
    @Bindable var questManager: QuestManager
    @Bindable var xpManager: XPManager

    @State private var showQuestDetail: DailyQuest?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting + Streak
                    headerSection

                    // Faith Rings
                    faithRingsSection

                    // Verse of the Day
                    verseCard

                    // Today's Quests
                    questsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color("BackgroundPrimary"))
            .navigationTitle("FaithForge")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $showQuestDetail) { quest in
                QuestDetailView(
                    quest: quest,
                    profile: profile,
                    questManager: questManager,
                    xpManager: xpManager
                )
            }
            .refreshable {
                questManager.refresh()
                xpManager.refresh()
            }
        }
    }

    // MARK: - Header (Greeting + Streak)

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello, \(profile.displayName)!")
                    .font(.title2.bold())
                    .foregroundStyle(Color("TextPrimary"))

                Text(profile.level.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(Color("FaithBlue"))
            }

            Spacer()

            StreakFlameView(streak: profile.currentStreak)
        }
        .padding(.top, 8)
    }

    // MARK: - Faith Rings

    private var faithRingsSection: some View {
        VStack(spacing: 12) {
            Text("Today's Faith Rings")
                .font(.headline)
                .foregroundStyle(Color("TextPrimary"))
                .frame(maxWidth: .infinity, alignment: .leading)

            FaithRingsView(xpManager: xpManager)
        }
        .faithCard()
    }

    // MARK: - Verse of the Day

    private var verseCard: some View {
        let verse = VerseOfTheDay.today
        return VStack(alignment: .leading, spacing: 8) {
            Label("Verse of the Day", systemImage: "book.closed.fill")
                .font(.caption.bold())
                .foregroundStyle(Color("FaithGold"))

            Text("\"\(verse.text)\"")
                .font(.body)
                .foregroundStyle(Color("TextPrimary"))
                .italic()
                .fixedSize(horizontal: false, vertical: true)

            Text("— \(verse.reference)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .faithCard()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Daily Quests

    private var questsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Today's Quests")
                    .font(.headline)
                    .foregroundStyle(Color("TextPrimary"))

                Spacer()

                Text("\(questManager.completedCount)/\(questManager.todaysQuests.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(questManager.todaysQuests, id: \.id) { quest in
                QuestRow(quest: quest) {
                    showQuestDetail = quest
                }
            }
        }
    }
}

// MARK: - Quest Row

private struct QuestRow: View {
    let quest: DailyQuest
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Category icon
                Image(systemName: quest.category.icon)
                    .font(.title3)
                    .foregroundStyle(quest.isCompleted ? .secondary : categoryColor)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(quest.isCompleted ? Color.gray.opacity(0.1) : categoryColor.opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(quest.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(quest.isCompleted ? .secondary : Color("TextPrimary"))
                        .strikethrough(quest.isCompleted)

                    HStack(spacing: 6) {
                        Label(quest.category.rawValue, systemImage: quest.type.icon)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if quest.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color("FaithGreen"))
                } else {
                    Text("+\(quest.xpReward) XP")
                        .font(.caption.bold())
                        .foregroundStyle(Color("FaithGold"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color("FaithGold").opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .faithCard()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(quest.title), \(quest.isCompleted ? "completed" : "\(quest.xpReward) XP")")
    }

    private var categoryColor: Color {
        switch quest.category {
        case .theWord:   return Color("FaithBlue")
        case .prayer:    return Color("FaithGold")
        case .mission:   return Color("FaithWarm")
        case .restInGod: return Color("FaithGreen")
        }
    }
}
