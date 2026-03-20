// LeaderboardView.swift
// FaithForge
//
// Leaderboard rankings with weekly/monthly/all-time period tabs.

import SwiftUI

struct LeaderboardView: View {
    @Bindable var leaderboardService: LeaderboardService

    var body: some View {
        VStack(spacing: 0) {
            // Period picker
            Picker("Period", selection: $leaderboardService.selectedPeriod) {
                ForEach(LeaderboardPeriod.allCases) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .onChange(of: leaderboardService.selectedPeriod) {
                leaderboardService.fetchRankings()
            }

            if leaderboardService.isLoading {
                Spacer()
                ProgressView("Loading rankings...")
                Spacer()
            } else if leaderboardService.rankings.isEmpty {
                emptyState
            } else {
                rankingsList
            }
        }
        .refreshable {
            await leaderboardService.pullFromFirestore()
        }
    }

    // MARK: - Rankings List

    private var rankingsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                // Top 3 podium
                if leaderboardService.rankings.count >= 3 {
                    podiumView
                }

                // Full list
                ForEach(Array(leaderboardService.rankings.enumerated()), id: \.element.id) { index, entry in
                    RankRow(
                        rank: index + 1,
                        entry: entry,
                        period: leaderboardService.selectedPeriod
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Podium View (Top 3)

    private var podiumView: some View {
        let top3 = Array(leaderboardService.rankings.prefix(3))
        let period = leaderboardService.selectedPeriod

        return HStack(alignment: .bottom, spacing: 12) {
            // 2nd place
            if top3.count > 1 {
                PodiumEntry(rank: 2, entry: top3[1], period: period, height: 80)
            }

            // 1st place
            PodiumEntry(rank: 1, entry: top3[0], period: period, height: 100)

            // 3rd place
            if top3.count > 2 {
                PodiumEntry(rank: 3, entry: top3[2], period: period, height: 65)
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "person.3")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No rankings yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Complete quests to appear on the leaderboard!")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }
}

// MARK: - Podium Entry

private struct PodiumEntry: View {
    let rank: Int
    let entry: LeaderboardEntry
    let period: LeaderboardPeriod
    let height: CGFloat

    private var medalColor: Color {
        switch rank {
        case 1: return Color("FaithGold")
        case 2: return .gray
        case 3: return Color("FaithWarm")
        default: return .secondary
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            // Medal
            ZStack {
                Circle()
                    .fill(medalColor.opacity(0.2))
                    .frame(width: 52, height: 52)

                Image(systemName: entry.avatarSymbol)
                    .font(.title2)
                    .foregroundStyle(medalColor)
            }
            .overlay(alignment: .bottomTrailing) {
                Text("\(rank)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(medalColor)
                    .clipShape(Circle())
                    .offset(x: 4, y: 4)
            }

            Text(entry.displayName)
                .font(.caption.bold())
                .foregroundStyle(entry.isCurrentUser ? Color("FaithBlue") : Color("TextPrimary"))
                .lineLimit(1)

            Text("\(entry.xp(for: period)) XP")
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Podium bar
            RoundedRectangle(cornerRadius: 8)
                .fill(medalColor.opacity(0.3))
                .frame(height: height)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rank \(rank), \(entry.displayName), \(entry.xp(for: period)) XP")
    }
}

// MARK: - Rank Row

private struct RankRow: View {
    let rank: Int
    let entry: LeaderboardEntry
    let period: LeaderboardPeriod

    var body: some View {
        HStack(spacing: 12) {
            // Rank number
            Text("\(rank)")
                .font(.headline)
                .foregroundStyle(rank <= 3 ? rankColor : .secondary)
                .frame(width: 32)

            // Avatar
            Image(systemName: entry.avatarSymbol)
                .font(.title3)
                .foregroundStyle(entry.isCurrentUser ? Color("FaithBlue") : .secondary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(entry.isCurrentUser ? Color("FaithBlue").opacity(0.15) : Color.gray.opacity(0.1))
                )

            // Name + Level
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(entry.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(entry.isCurrentUser ? Color("FaithBlue") : Color("TextPrimary"))

                    if entry.isCurrentUser {
                        Text("(You)")
                            .font(.caption2)
                            .foregroundStyle(Color("FaithBlue"))
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: entry.level.icon)
                        .font(.caption2)
                    Text(entry.level.rawValue)
                        .font(.caption2)

                    if entry.currentStreak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                            Text("\(entry.currentStreak)")
                                .font(.caption2)
                        }
                        .foregroundStyle(.orange)
                    }
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            // XP
            Text("\(entry.xp(for: period))")
                .font(.headline)
                .foregroundStyle(Color("TextPrimary"))
            Text("XP")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            entry.isCurrentUser
                ? Color("FaithBlue").opacity(0.08)
                : Color("BackgroundSecondary")
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Color("FaithGold")
        case 2: return .gray
        case 3: return Color("FaithWarm")
        default: return .secondary
        }
    }
}
