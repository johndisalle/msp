// QuestsListView.swift
// FaithForge
//
// Full quest list tab with category filtering and completion state.

import SwiftUI

struct QuestsListView: View {
    @Bindable var profile: UserProfile
    @Bindable var questManager: QuestManager
    @Bindable var xpManager: XPManager

    @State private var selectedFilter: QuestCategory?
    @State private var showQuestDetail: DailyQuest?

    private var filteredQuests: [DailyQuest] {
        guard let filter = selectedFilter else { return questManager.todaysQuests }
        return questManager.todaysQuests.filter { $0.category == filter }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Category filter chips
                    filterChips

                    // Stats bar
                    statsBar

                    // Quest list
                    if filteredQuests.isEmpty {
                        emptyState
                    } else {
                        questList
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color("BackgroundPrimary"))
            .navigationTitle("Quests")
            .sheet(item: $showQuestDetail) { quest in
                QuestDetailView(
                    quest: quest,
                    profile: profile,
                    questManager: questManager,
                    xpManager: xpManager
                )
            }
        }
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterChip(title: "All", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }

                ForEach(QuestCategory.allCases) { category in
                    FilterChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedFilter == category
                    ) {
                        selectedFilter = (selectedFilter == category) ? nil : category
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 20) {
            StatItem(
                value: "\(questManager.completedCount)",
                label: "Completed",
                icon: "checkmark.circle.fill",
                color: Color("FaithGreen")
            )

            StatItem(
                value: "\(questManager.todaysQuests.count - questManager.completedCount)",
                label: "Remaining",
                icon: "circle.dotted",
                color: Color("FaithBlue")
            )

            StatItem(
                value: "+\(xpManager.todayTotalXP)",
                label: "XP Today",
                icon: "star.fill",
                color: Color("FaithGold")
            )
        }
        .faithCard()
    }

    // MARK: - Quest List

    private var questList: some View {
        VStack(spacing: 10) {
            ForEach(filteredQuests, id: \.id) { quest in
                QuestListRow(quest: quest) {
                    showQuestDetail = quest
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("No quests in this category")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color("FaithBlue") : Color("BackgroundSecondary"))
            .foregroundStyle(isSelected ? .white : Color("TextPrimary"))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Stat Item

private struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
                .foregroundStyle(Color("TextPrimary"))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Quest List Row

private struct QuestListRow: View {
    let quest: DailyQuest
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Type icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(quest.isCompleted ? Color.gray.opacity(0.1) : rowColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: quest.category.icon)
                        .font(.body)
                        .foregroundStyle(quest.isCompleted ? .secondary : rowColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(quest.isCompleted ? .secondary : Color("TextPrimary"))
                        .strikethrough(quest.isCompleted)

                    HStack(spacing: 8) {
                        Label(quest.type.rawValue, systemImage: quest.type.icon)
                        Text("\u{2022}")
                        Text(quest.category.rawValue)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if quest.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color("FaithGreen"))
                } else {
                    VStack(spacing: 2) {
                        Text("+\(quest.xpReward)")
                            .font(.caption.bold())
                        Text("XP")
                            .font(.caption2)
                    }
                    .foregroundStyle(Color("FaithGold"))
                }
            }
            .faithCard()
        }
        .buttonStyle(.plain)
    }

    private var rowColor: Color {
        switch quest.category {
        case .theWord:   return Color("FaithBlue")
        case .prayer:    return Color("FaithGold")
        case .mission:   return Color("FaithWarm")
        case .restInGod: return Color("FaithGreen")
        }
    }
}
