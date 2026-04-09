import SwiftUI
import SwiftData

struct SanctuaryView: View {
    @State private var appeared = false
    @Query(filter: #Predicate<Journey> { $0.isActive }) private var journeys: [Journey]

    private var isPremium: Bool {
        UserDefaults.standard.bool(forKey: "isPremiumUser")
    }

    // MARK: - Fallback Verses

    private static let fallbackVerses: [(text: String, reference: String)] = [
        ("Be still, and know that I am God.", "Psalm 46:10"),
        ("The Lord is my shepherd; I shall not want.", "Psalm 23:1"),
        ("Trust in the Lord with all your heart, and lean not on your own understanding.", "Proverbs 3:5"),
        ("I can do all things through Christ who strengthens me.", "Philippians 4:13"),
        ("For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future.", "Jeremiah 29:11"),
        ("Cast all your anxiety on him because he cares for you.", "1 Peter 5:7"),
        ("The Lord is near to the brokenhearted and saves the crushed in spirit.", "Psalm 34:18")
    ]

    // MARK: - Community Highlights

    private let highlights = [
        "Believers around the world are praying together.",
        "Join a global community lifting prayers to God.",
        "Your prayers and testimonies encourage others.",
        "Faith grows stronger when shared with others."
    ]

    // MARK: - Computed Verse

    private var dailyVerse: (text: String, reference: String) {
        // Try to pull from active journey's current day
        if let journey = journeys.first,
           let days = journey.days {
            let sorted = days.sorted { $0.dayNumber < $1.dayNumber }
            if let currentDay = sorted.first(where: { $0.isUnlocked && !$0.isCompleted }),
               !currentDay.scriptureText.isEmpty {
                return (currentDay.scriptureText, currentDay.scriptureReference)
            }
        }
        // Fallback: rotate based on day of year
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return Self.fallbackVerses[dayOfYear % Self.fallbackVerses.count]
    }

    private var communityHighlight: String {
        let day = Calendar.current.component(.day, from: Date())
        return highlights[day % highlights.count]
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AJTheme.paddingLarge) {

                    // MARK: Hero — Daily Verse

                    verseHero
                        .padding(.horizontal)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.05), value: appeared)

                    // MARK: Quick Action — Breathe

                    breatheQuickAction
                        .padding(.horizontal)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.12), value: appeared)

                    // MARK: Community Section

                    VStack(spacing: 12) {
                        sectionHeader("Community")

                        NavigationLink {
                            PrayerWallView()
                        } label: {
                            SanctuaryCard(
                                icon: "hands.sparkles.fill",
                                color: .blue,
                                title: "Prayer Wall",
                                subtitle: "Lift up requests and pray for others",
                                badgeCount: PrayerWallService.shared.activeCount
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)

                        NavigationLink {
                            TestimonyWallView()
                        } label: {
                            SanctuaryCard(
                                icon: "text.quote",
                                color: .pink,
                                title: "Testimony Wall",
                                subtitle: "Real stories of God at work",
                                badgeCount: 0
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)

                        Text("Sharing with the community is a Premium feature")
                            .font(AJTheme.captionFont.italic())
                            .foregroundStyle(AJTheme.secondaryText)
                            .padding(.horizontal)
                    }
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)

                    // MARK: Practice Section

                    VStack(spacing: 12) {
                        sectionHeader("Practice")

                        NavigationLink {
                            BreathingMeditationView()
                        } label: {
                            SanctuaryCard(
                                icon: "wind",
                                color: .teal,
                                title: "Breathe with Scripture",
                                subtitle: isPremium ? "8 guided sessions" : "8 sessions \u{00B7} 2 free",
                                badgeCount: 0
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)

                        NavigationLink {
                            ScriptureMemoryView()
                        } label: {
                            SanctuaryCard(
                                icon: "brain.head.profile",
                                color: .purple,
                                title: "Scripture Memory",
                                subtitle: "Flashcard practice",
                                badgeCount: ScriptureMemoryService.shared.loadVerses().count
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)

                    // MARK: Reflect Section

                    VStack(spacing: 12) {
                        sectionHeader("Reflect")

                        NavigationLink {
                            GodMomentsView()
                        } label: {
                            SanctuaryCard(
                                icon: "camera.viewfinder",
                                color: .orange,
                                title: "God Moments",
                                subtitle: "Capture God at work in your life",
                                badgeCount: GodMomentsService.shared.loadMoments().count
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.38), value: appeared)

                    // MARK: Connect Section

                    VStack(spacing: 12) {
                        sectionHeader("Connect")

                        NavigationLink {
                            FindChurchView()
                        } label: {
                            SanctuaryCard(
                                icon: "building.columns.fill",
                                color: .indigo,
                                title: "Find a Church",
                                subtitle: "Discover churches near you",
                                badgeCount: 0
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.44), value: appeared)

                    // MARK: Community Highlight

                    Text(communityHighlight)
                        .font(AJTheme.captionFont.italic())
                        .foregroundStyle(AJTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(AJTheme.paddingMedium)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: AJTheme.cornerRadiusSmall)
                                .fill(AJTheme.gold.opacity(0.06))
                        )
                        .padding(.horizontal)
                        .padding(.bottom, AJTheme.paddingMedium)
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

    // MARK: - Verse Hero

    private var verseHero: some View {
        VStack(spacing: 12) {
            // Gold accent bar at top
            RoundedRectangle(cornerRadius: 2)
                .fill(AJTheme.gold)
                .frame(width: 40, height: 3)
                .padding(.top, 4)

            Text("\"\(dailyVerse.text)\"")
                .font(.system(.title3, design: .serif).italic())
                .foregroundStyle(AJTheme.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AJTheme.paddingSmall)

            Text(dailyVerse.reference)
                .font(.caption.bold())
                .foregroundStyle(AJTheme.gold)
        }
        .padding(AJTheme.paddingLarge)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AJTheme.cornerRadius)
                .fill(AJTheme.cream)
                .overlay(
                    RoundedRectangle(cornerRadius: AJTheme.cornerRadius)
                        .stroke(AJTheme.gold.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
        )
    }

    // MARK: - Breathe Quick Action

    private var breatheQuickAction: some View {
        VStack(spacing: 8) {
            NavigationLink {
                BreathingMeditationView()
            } label: {
                Label("Breathe with Scripture", systemImage: "wind")
            }
            .buttonStyle(AJBreathButtonStyle())

            NavigationLink {
                BreathingMeditationView()
            } label: {
                Text("See all sessions")
                    .font(AJTheme.captionFont)
                    .foregroundStyle(AJTheme.secondaryText)
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.bold())
            .foregroundStyle(AJTheme.secondaryText)
            .tracking(1.2)
            .padding(.horizontal)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Breathe Button Style (teal tint variant of AJSecondaryButtonStyle)

private struct AJBreathButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .serif, weight: .semibold))
            .foregroundColor(.teal)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.teal.opacity(0.1))
            .cornerRadius(AJTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AJTheme.cornerRadius)
                    .stroke(Color.teal.opacity(0.3), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
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
