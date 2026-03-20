import SwiftUI
import SwiftData

struct SharingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var generosityLevel: String = ""
    @State private var streak: Int = 0
    @State private var totalGiven: Decimal = 0
    @State private var badgeCount: Int = 0
    @State private var showingInviteShare = false
    @State private var showingTestimonyShare = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Invite Friends
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(Color("AccentGold"))

                    Text("Invite a Friend")
                        .font(.title3.bold())

                    Text("Help someone you love start their stewardship journey. Share Tithe Steward and grow together in generosity.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        showingInviteShare = true
                    } label: {
                        Label("Send Invitation", systemImage: "square.and.arrow.up")
                            .accentButtonStyle()
                    }
                }
                .cardStyle()
                .padding(.horizontal)

                // Share Your Testimony
                VStack(spacing: 16) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color("AccentGold"))

                    Text("Share Your Testimony")
                        .font(.title3.bold())

                    Text("Your generosity journey can inspire others. Share how God has moved in your finances.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    // Stats preview
                    HStack(spacing: 20) {
                        StatPill(label: generosityLevel, icon: "crown.fill")
                        StatPill(label: "\(streak) mo streak", icon: "flame.fill")
                        StatPill(label: "\(badgeCount) badges", icon: "trophy.fill")
                    }

                    Button {
                        showingTestimonyShare = true
                    } label: {
                        Label("Share My Journey", systemImage: "heart.fill")
                            .accentButtonStyle()
                    }
                }
                .cardStyle()
                .padding(.horizontal)

                // Share milestones
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Share")
                        .font(.headline)

                    ShareOptionRow(
                        icon: "heart.circle.fill",
                        title: "Tithe Goal Met",
                        subtitle: "Share that you hit your tithe goal this month",
                        shareText: "I just met my tithe goal this month! Honoring God with my firstfruits. #TitheSteward #Tithe"
                    )

                    ShareOptionRow(
                        icon: "flame.fill",
                        title: "Giving Streak",
                        subtitle: "Share your \(streak)-month giving streak",
                        shareText: "I'm on a \(streak)-month giving streak with Tithe Steward! Consistency is key to faithful stewardship. #TitheSteward #Generosity"
                    )

                    ShareOptionRow(
                        icon: "trophy.fill",
                        title: "Badge Earned",
                        subtitle: "Share your latest achievement",
                        shareText: "I've earned \(badgeCount) generosity badges on Tithe Steward! \"Well done, good and faithful servant.\" — Matthew 25:21 #TitheSteward"
                    )
                }
                .cardStyle()
                .padding(.horizontal)

                // Scripture
                VStack(spacing: 4) {
                    Text("\"And let us consider how we may spur one another on toward love and good deeds.\"")
                        .font(.caption.italic())
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Text("— Hebrews 10:24")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .padding(.vertical)
        }
        .navigationTitle("Share & Invite")
        .onAppear { loadData() }
        .sheet(isPresented: $showingInviteShare) {
            ShareTextActivityView(text: "I've been using Tithe Steward to track my giving and grow in generosity. It's helped me stay faithful with my tithe and see how God provides. You should check it out! #TitheSteward")
        }
        .sheet(isPresented: $showingTestimonyShare) {
            ShareTextActivityView(text: testimonyText)
        }
    }

    private var testimonyText: String {
        var text = "My stewardship journey with Tithe Steward:\n\n"
        text += "Level: \(generosityLevel)\n"
        text += "Streak: \(streak) months of faithful giving\n"
        text += "Badges earned: \(badgeCount)\n\n"
        text += "\"Give, and it will be given to you. A good measure, pressed down, shaken together and running over.\" — Luke 6:38\n\n"
        text += "#TitheSteward #Generosity #FaithfulSteward"
        return text
    }

    private func loadData() {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = (try? modelContext.fetch(descriptor))?.first else { return }

        let titheService = TitheCalculatorService(modelContext: modelContext)
        let score = titheService.calculateGenerosityScore(for: profile)
        generosityLevel = score.level.rawValue
        streak = profile.generosityStreak
        totalGiven = profile.totalGivenAllTime
        badgeCount = profile.badges.count
    }
}

// MARK: - Components

struct StatPill: View {
    let label: String
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption2)
        }
        .foregroundColor(Color("AccentGold"))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color("AccentGold").opacity(0.1))
        .clipShape(Capsule())
    }
}

struct ShareOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let shareText: String
    @State private var showingShare = false

    var body: some View {
        Button {
            showingShare = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(Color("AccentGold"))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "square.and.arrow.up")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingShare) {
            ShareTextActivityView(text: shareText)
        }
    }
}

struct ShareTextActivityView: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        SharingView()
    }
}
