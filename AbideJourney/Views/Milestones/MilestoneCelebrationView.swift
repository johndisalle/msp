import SwiftUI

/// Shareable milestone cards shown at days 7, 14, 21, 30, and 40.
struct MilestoneCelebrationView: View {
    @Environment(\.dismiss) private var dismiss
    let dayNumber: Int
    let journeyTitle: String
    let journeyTheme: JourneyTheme
    let userName: String

    @State private var animateIn = false
    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?

    static let milestoneDays: Set<Int> = [7, 14, 21, 30, 40]

    private var milestone: Milestone {
        Milestone.forDay(dayNumber)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Shareable card
                milestoneCard
                    .scaleEffect(animateIn ? 1.0 : 0.8)
                    .opacity(animateIn ? 1.0 : 0)

                // Share button
                Button {
                    shareCard()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share My Milestone")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)

                Button("Continue") {
                    dismiss()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                    animateIn = true
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = shareImage {
                    ShareSheet(items: [image, milestone.shareText(name: userName, journey: journeyTitle)])
                }
            }
        }
    }

    // MARK: - Milestone Card (also rendered to image for sharing)

    private var milestoneCard: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(milestone.color.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: milestone.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(milestone.color)
                    .symbolEffect(.bounce, value: animateIn)
            }

            // Day badge
            Text("DAY \(dayNumber)")
                .font(.caption.bold())
                .tracking(2)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(milestone.color.opacity(0.15))
                .foregroundStyle(milestone.color)
                .clipShape(Capsule())

            // Title
            Text(milestone.title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            // Subtitle
            Text(milestone.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            // Journey info
            HStack(spacing: 6) {
                Image(systemName: journeyTheme.icon)
                    .font(.caption)
                Text(journeyTitle)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)

            // Branding
            Text("Abide Journey")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        )
        .padding(.horizontal)
    }

    // MARK: - Share

    @MainActor
    private func shareCard() {
        let renderer = ImageRenderer(content: milestoneCardForSharing)
        renderer.scale = 3.0
        if let image = renderer.uiImage {
            shareImage = image
            showingShareSheet = true
        }
    }

    private var milestoneCardForSharing: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(milestone.color.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: milestone.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(milestone.color)
            }

            Text("DAY \(dayNumber)")
                .font(.caption.bold())
                .tracking(2)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(milestone.color.opacity(0.15))
                .foregroundStyle(milestone.color)
                .clipShape(Capsule())

            Text(milestone.title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text(milestone.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            HStack(spacing: 6) {
                Image(systemName: journeyTheme.icon)
                    .font(.caption)
                Text(journeyTitle)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)

            Text("Abide Journey")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(32)
        .frame(width: 360)
        .background(AJTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Milestone Data

struct Milestone {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    func shareText(name: String, journey: String) -> String {
        "\(name) just reached \(title.lowercased()) on the \(journey) journey with Abide Journey!"
    }

    static func forDay(_ day: Int) -> Milestone {
        switch day {
        case 7:
            return Milestone(
                title: "First Week Complete!",
                subtitle: "You showed up for 7 days.\nThat's how transformation starts.",
                icon: "sparkles",
                color: .blue
            )
        case 14:
            return Milestone(
                title: "Two Weeks Strong!",
                subtitle: "Halfway to halfway.\nYou're building a real habit.",
                icon: "flame.fill",
                color: .orange
            )
        case 21:
            return Milestone(
                title: "21 Days — A Habit Formed!",
                subtitle: "They say it takes 21 days to build a habit.\nLook at you go.",
                icon: "trophy.fill",
                color: .yellow
            )
        case 30:
            return Milestone(
                title: "30 Days of Faithfulness!",
                subtitle: "Only 10 days left.\nYou've come so far — finish strong.",
                icon: "star.fill",
                color: .purple
            )
        case 40:
            return Milestone(
                title: "Journey Complete!",
                subtitle: "40 days of walking with God.\nThis is just the beginning.",
                icon: "checkmark.seal.fill",
                color: .green
            )
        default:
            return Milestone(
                title: "Keep Going!",
                subtitle: "Every day matters.",
                icon: "heart.fill",
                color: .accent
            )
        }
    }
}
