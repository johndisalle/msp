import SwiftUI
import SwiftData

struct BadgeGalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var earnedBadges: [GenerosityBadge] = []
    @State private var selectedBadge: BadgeType?
    @State private var showingShareSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header stats
                HStack(spacing: 30) {
                    VStack {
                        Text("\(earnedBadges.count)")
                            .font(.title.bold())
                            .foregroundColor(Color("AccentGold"))
                        Text("Earned")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack {
                        Text("\(BadgeType.allCases.count - earnedBadges.count)")
                            .font(.title.bold())
                            .foregroundColor(.secondary)
                        Text("Remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top)

                // Earned Badges
                if !earnedBadges.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Earned Badges")
                            .font(.headline)
                            .padding(.horizontal)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ], spacing: 16) {
                            ForEach(earnedBadges, id: \.badgeTypeRaw) { badge in
                                BadgeTile(
                                    badgeType: badge.badgeType,
                                    isEarned: true,
                                    isNew: badge.isNew
                                )
                                .onTapGesture {
                                    selectedBadge = badge.badgeType
                                    markSeen(badge)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Locked Badges
                let locked = BadgeType.allCases.filter { type in
                    !earnedBadges.contains { $0.badgeType == type }
                }
                if !locked.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Keep Going!")
                            .font(.headline)
                            .padding(.horizontal)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ], spacing: 16) {
                            ForEach(locked, id: \.rawValue) { type in
                                BadgeTile(badgeType: type, isEarned: false, isNew: false)
                                    .onTapGesture {
                                        selectedBadge = type
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Scripture
                VStack(spacing: 4) {
                    Text("\"His master replied, 'Well done, good and faithful servant!'\"")
                        .font(.caption.italic())
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Text("— Matthew 25:21")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .navigationTitle("Generosity Badges")
        .onAppear { loadBadges() }
        .sheet(item: $selectedBadge) { type in
            BadgeDetailSheet(
                badgeType: type,
                isEarned: earnedBadges.contains { $0.badgeType == type },
                earnedDate: earnedBadges.first { $0.badgeType == type }?.earnedDate
            )
        }
    }

    private func loadBadges() {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = (try? modelContext.fetch(descriptor))?.first else { return }

        let badgeService = BadgeService(modelContext: modelContext)
        _ = badgeService.evaluateAndAwardBadges(for: profile)
        earnedBadges = badgeService.fetchBadges(for: profile)
    }

    private func markSeen(_ badge: GenerosityBadge) {
        let badgeService = BadgeService(modelContext: modelContext)
        badgeService.markBadgeSeen(badge)
    }
}

// MARK: - Badge Tile

struct BadgeTile: View {
    let badgeType: BadgeType
    let isEarned: Bool
    let isNew: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isEarned ? Color(badgeType.color).opacity(0.2) : Color(.systemGray5))
                    .frame(width: 64, height: 64)

                Image(systemName: badgeType.icon)
                    .font(.title2)
                    .foregroundColor(isEarned ? Color(badgeType.color) : .gray.opacity(0.4))

                if isNew {
                    Circle()
                        .fill(.red)
                        .frame(width: 12, height: 12)
                        .offset(x: 24, y: -24)
                }

                if !isEarned {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .offset(y: 20)
                }
            }

            Text(badgeType.rawValue)
                .font(.caption2)
                .foregroundColor(isEarned ? .primary : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Badge Detail Sheet

struct BadgeDetailSheet: View {
    let badgeType: BadgeType
    let isEarned: Bool
    let earnedDate: Date?
    @Environment(\.dismiss) var dismiss
    @State private var showingShare = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Badge icon
                ZStack {
                    Circle()
                        .fill(isEarned ? Color(badgeType.color).opacity(0.2) : Color(.systemGray5))
                        .frame(width: 120, height: 120)

                    Image(systemName: badgeType.icon)
                        .font(.system(size: 50))
                        .foregroundColor(isEarned ? Color(badgeType.color) : .gray)
                }

                Text(badgeType.rawValue)
                    .font(.title2.bold())

                Text(badgeType.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                if let date = earnedDate {
                    Text("Earned \(date.formatted(date: .long, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Scripture
                VStack(spacing: 4) {
                    Text(badgeType.verse)
                        .font(.callout.italic())
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }

                Spacer()

                if isEarned {
                    Button {
                        showingShare = true
                    } label: {
                        Label("Share Achievement", systemImage: "square.and.arrow.up")
                            .accentButtonStyle()
                    }
                    .padding(.horizontal)
                } else {
                    Text("Keep giving faithfully to unlock this badge!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showingShare) {
                ShareBadgeActivityView(badgeType: badgeType)
            }
        }
    }
}

// MARK: - Share

struct ShareBadgeActivityView: UIViewControllerRepresentable {
    let badgeType: BadgeType

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let text = "I just earned the \"\(badgeType.rawValue)\" badge on Tithe Steward! \(badgeType.verse) #TitheSteward #Generosity"
        return UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension BadgeType: Identifiable {
    var id: String { rawValue }
}

#Preview {
    NavigationStack {
        BadgeGalleryView()
    }
}
