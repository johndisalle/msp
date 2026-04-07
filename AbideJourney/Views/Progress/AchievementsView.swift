import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Query private var journeys: [Journey]
    @Query private var journalEntries: [JournalEntry]
    @State private var earnedIDs: Set<String> = []
    @State private var selectedBadge: AchievementBadge?
    @State private var showBadgeDetail = false

    private let service = AchievementService.shared

    private var earnedBadges: [AchievementBadge] {
        BadgeCatalog.all.filter { earnedIDs.contains($0.id) }
    }

    private var lockedBadges: [AchievementBadge] {
        BadgeCatalog.all.filter { !earnedIDs.contains($0.id) }
    }

    private var level: (name: String, number: Int, progress: Double) {
        let count = earnedIDs.count
        let total = BadgeCatalog.all.count
        switch count {
        case 0...2: return ("Seedling", 1, Double(count) / 3.0)
        case 3...6: return ("Sprout", 2, Double(count - 3) / 4.0)
        case 7...11: return ("Rooted", 3, Double(count - 7) / 5.0)
        case 12...17: return ("Flourishing", 4, Double(count - 12) / 6.0)
        default: return ("Mighty Oak", 5, Double(count) / Double(total))
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Level card
                levelCard

                // Earned badges
                if !earnedBadges.isEmpty {
                    badgeSection(title: "Earned", badges: earnedBadges, locked: false)
                }

                // Locked badges
                if !lockedBadges.isEmpty {
                    badgeSection(title: "Keep Going", badges: lockedBadges, locked: true)
                }
            }
            .padding(.vertical)
        }
        .ajScreenBackground()
        .navigationTitle("Achievements")
        .onAppear {
            service.evaluate(journeys: journeys, journalEntryCount: journalEntries.count)
            earnedIDs = service.earnedBadgeIDs
            service.markAllSeen()
        }
        .sheet(isPresented: $showBadgeDetail) {
            if let badge = selectedBadge {
                BadgeDetailSheet(badge: badge, isEarned: earnedIDs.contains(badge.id))
            }
        }
    }

    // MARK: - Level Card

    private var levelCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(AJTheme.sage.opacity(0.2), lineWidth: 6)
                        .frame(width: 72, height: 72)
                    Circle()
                        .trim(from: 0, to: level.progress)
                        .stroke(AJTheme.sage, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 72, height: 72)
                        .rotationEffect(.degrees(-90))
                    Text("Lv.\(level.number)")
                        .font(.system(.headline, design: .serif, weight: .bold))
                        .foregroundStyle(AJTheme.sage)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(level.name)
                        .font(AJTheme.headlineFont)
                    Text("\(earnedIDs.count) of \(BadgeCatalog.all.count) badges earned")
                        .font(.subheadline)
                        .foregroundStyle(AJTheme.secondaryText)

                    ProgressView(value: Double(earnedIDs.count), total: Double(BadgeCatalog.all.count))
                        .tint(AJTheme.sage)
                }
            }
        }
        .ajCard()
        .padding(.horizontal)
    }

    // MARK: - Badge Grid

    private func badgeSection(title: String, badges: [AchievementBadge], locked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AJTheme.subheadlineFont)
                .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                ForEach(badges) { badge in
                    Button {
                        selectedBadge = badge
                        showBadgeDetail = true
                    } label: {
                        BadgeCell(badge: badge, locked: locked)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Badge Cell

private struct BadgeCell: View {
    let badge: AchievementBadge
    let locked: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(locked ? Color.gray.opacity(0.1) : badge.color.opacity(0.15))
                    .frame(width: 60, height: 60)

                Image(systemName: badge.icon)
                    .font(.title2)
                    .foregroundStyle(locked ? .gray.opacity(0.4) : badge.color)
            }

            Text(badge.name)
                .font(.caption2.bold())
                .foregroundStyle(locked ? AJTheme.secondaryText.opacity(0.5) : AJTheme.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(locked ? AJTheme.cardBackground.opacity(0.5) : AJTheme.cardBackground)
                .shadow(color: locked ? .clear : AJTheme.cardShadow, radius: 4, x: 0, y: 2)
        )
        .opacity(locked ? 0.6 : 1)
    }
}

// MARK: - Badge Detail Sheet

private struct BadgeDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let badge: AchievementBadge
    let isEarned: Bool

    @State private var appeared = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(isEarned ? badge.color.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(appeared ? 1 : 0.5)

                    Image(systemName: badge.icon)
                        .font(.system(size: 52))
                        .foregroundStyle(isEarned ? badge.color : .gray.opacity(0.4))
                        .scaleEffect(appeared ? 1 : 0.5)
                }

                VStack(spacing: 8) {
                    Text(badge.name)
                        .font(AJTheme.titleFont)

                    Text(badge.description)
                        .font(.body)
                        .foregroundStyle(AJTheme.secondaryText)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 6) {
                        Image(systemName: badge.category.icon)
                            .font(.caption)
                        Text(badge.category.rawValue)
                            .font(.caption.bold())
                    }
                    .foregroundStyle(badge.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(badge.color.opacity(0.12))
                    .clipShape(Capsule())
                    .padding(.top, 4)
                }

                if isEarned {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(AJTheme.success)
                        Text("Earned!")
                            .font(.headline)
                            .foregroundStyle(AJTheme.success)
                    }
                } else {
                    Text("Keep going — you're getting closer!")
                        .font(.subheadline)
                        .foregroundStyle(AJTheme.secondaryText)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AJTheme.sage)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}

// MARK: - New Badge Toast (overlay in DailyExperienceView)

struct NewBadgeToast: View {
    let badge: AchievementBadge
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(badge.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: badge.icon)
                    .font(.title3)
                    .foregroundStyle(badge.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Badge Earned!")
                    .font(.caption2.bold())
                    .foregroundStyle(AJTheme.secondaryText)
                Text(badge.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(AJTheme.primaryText)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AJTheme.success)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AJTheme.cardBackground)
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 24)
        .offset(y: appeared ? 0 : -80)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { appeared = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onDismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
            .modelContainer(for: Journey.self, inMemory: true)
    }
}
