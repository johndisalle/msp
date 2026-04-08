import SwiftUI

struct SanctuaryView: View {
    @State private var appeared = false

    private var isPremium: Bool {
        UserDefaults.standard.bool(forKey: "isPremiumUser")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 32))
                            .foregroundStyle(AJTheme.gold)
                            .opacity(appeared ? 1 : 0)
                            .scaleEffect(appeared ? 1 : 0.5)

                        Text("Your Sacred Space")
                            .font(.subheadline)
                            .foregroundStyle(AJTheme.secondaryText)
                            .opacity(appeared ? 1 : 0)
                    }
                    .padding(.top, 4)
                    .animation(.easeOut(duration: 0.6), value: appeared)

                    // Prayer Wall
                    NavigationLink {
                        PrayerWallView()
                    } label: {
                        SanctuaryCard(
                            icon: "hands.sparkles.fill",
                            color: .blue,
                            title: "Prayer Wall",
                            subtitle: "Lift up your requests and celebrate answered prayers",
                            badgeCount: PrayerWallService.shared.activeCount
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)

                    // Breathe with Scripture
                    NavigationLink {
                        BreathingMeditationView()
                    } label: {
                        SanctuaryCard(
                            icon: "wind",
                            color: .teal,
                            title: "Breathe with Scripture",
                            subtitle: "Guided breathing exercises paired with God's Word",
                            badgeCount: 0
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)

                    // God Moments
                    NavigationLink {
                        GodMomentsView()
                    } label: {
                        SanctuaryCard(
                            icon: "camera.viewfinder",
                            color: .orange,
                            title: "God Moments",
                            subtitle: "Capture and remember God at work in your life",
                            badgeCount: GodMomentsService.shared.loadMoments().count
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)

                    // Scripture Memory
                    NavigationLink {
                        ScriptureMemoryView()
                    } label: {
                        SanctuaryCard(
                            icon: "brain.head.profile",
                            color: .purple,
                            title: "Scripture Memory",
                            subtitle: "Hide God's Word in your heart with flashcard practice",
                            badgeCount: ScriptureMemoryService.shared.loadVerses().count
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: appeared)

                    // Daily verse at bottom
                    VStack(spacing: 8) {
                        Text("\"Be still, and know that I am God.\"")
                            .font(.subheadline.italic())
                            .foregroundStyle(AJTheme.secondaryText)
                        Text("Psalm 46:10")
                            .font(.caption.bold())
                            .foregroundStyle(AJTheme.gold)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: appeared)
                }
                .padding(.vertical)
            }
            .ajScreenBackground()
            .navigationTitle("Sanctuary")
            .onAppear {
                withAnimation {
                    appeared = true
                }
            }
        }
    }
}

// MARK: - Sanctuary Card

private struct SanctuaryCard: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let badgeCount: Int

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(AJTheme.primaryText)

                    if badgeCount > 0 {
                        Text("\(badgeCount)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(color))
                    }
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AJTheme.secondaryText)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AJTheme.cardBackground)
                .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
        )
    }
}

#Preview {
    SanctuaryView()
}
