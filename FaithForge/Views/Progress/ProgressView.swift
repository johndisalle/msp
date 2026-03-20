// ProgressView.swift
// FaithForge
//
// Progress tab: level display, XP bar, weekly chart, badge gallery.

import SwiftUI
import SwiftData

struct ProgressView: View {
    @Bindable var profile: UserProfile
    @Bindable var xpManager: XPManager
    @Query private var badges: [Badge]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Level Card
                    levelCard

                    // Weekly XP Chart
                    weeklyChart

                    // Badge Gallery
                    badgeGallery

                    // Stats Summary
                    statsSummary
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color("BackgroundPrimary"))
            .navigationTitle("Progress")
        }
    }

    // MARK: - Level Card

    private var levelCard: some View {
        VStack(spacing: 16) {
            // Level icon and name
            HStack(spacing: 16) {
                Image(systemName: profile.level.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(Color("FaithGold"))
                    .frame(width: 64, height: 64)
                    .background(Color("FaithGold").opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.level.rawValue)
                        .font(.title2.bold())
                        .foregroundStyle(Color("TextPrimary"))

                    Text("Total XP: \(profile.totalXP)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // XP Progress Bar
            VStack(spacing: 6) {
                XPBarView(progress: profile.levelProgress)

                HStack {
                    Text(profile.level.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let next = profile.level.next {
                        Text("\(profile.xpToNextLevel) XP to \(next.rawValue)")
                            .font(.caption2)
                            .foregroundStyle(Color("FaithBlue"))
                    } else {
                        Text("Max Level!")
                            .font(.caption2.bold())
                            .foregroundStyle(Color("FaithGold"))
                    }
                }
            }
        }
        .faithCard()
    }

    // MARK: - Weekly Chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)
                .foregroundStyle(Color("TextPrimary"))

            let history = xpManager.weeklyXPHistory()
            let maxXP = max(history.map(\.xp).max() ?? 1, 1)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(history, id: \.date) { entry in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(entry.date.isToday ? Color("FaithBlue") : Color("FaithBlue").opacity(0.4))
                            .frame(height: max(CGFloat(entry.xp) / CGFloat(maxXP) * 100, 4))

                        Text(entry.date.shortWeekday)
                            .font(.caption2)
                            .foregroundStyle(entry.date.isToday ? Color("FaithBlue") : .secondary)

                        Text("\(entry.xp)")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 140)
        }
        .faithCard()
    }

    // MARK: - Badge Gallery

    private var badgeGallery: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Badges")
                    .font(.headline)
                    .foregroundStyle(Color("TextPrimary"))

                Spacer()

                Text("\(badges.filter(\.isUnlocked).count)/\(badges.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 16) {
                ForEach(badges, id: \.id) { badge in
                    BadgeCell(badge: badge)
                }
            }
        }
        .faithCard()
    }

    // MARK: - Stats Summary

    private var statsSummary: some View {
        VStack(spacing: 12) {
            Text("Stats")
                .font(.headline)
                .foregroundStyle(Color("TextPrimary"))
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Current Streak", value: "\(profile.currentStreak)", icon: "flame.fill", color: Color("FaithWarm"))
                StatCard(title: "Longest Streak", value: "\(profile.longestStreak)", icon: "trophy.fill", color: Color("FaithGold"))
                StatCard(title: "Total XP", value: "\(profile.totalXP)", icon: "star.fill", color: Color("FaithBlue"))
                StatCard(title: "Today's XP", value: "\(xpManager.todayTotalXP)", icon: "bolt.fill", color: Color("FaithGreen"))
            }
        }
    }
}

// MARK: - Badge Cell

private struct BadgeCell: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: badge.icon)
                .font(.title2)
                .foregroundStyle(badge.isUnlocked ? Color("FaithGold") : .secondary.opacity(0.4))
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(badge.isUnlocked ? Color("FaithGold").opacity(0.15) : Color.gray.opacity(0.1))
                )

            Text(badge.name)
                .font(.caption2)
                .foregroundStyle(badge.isUnlocked ? Color("TextPrimary") : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .accessibilityLabel("\(badge.name), \(badge.isUnlocked ? "unlocked" : "locked")")
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(Color("TextPrimary"))

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}
