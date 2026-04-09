import SwiftUI
import SwiftData

/// Journey marketplace — browse themes, discover premium features, and start new journeys.
struct DiscoverView: View {
    @Query(filter: #Predicate<Journey> { $0.isActive }) private var journeys: [Journey]
    @Query private var profiles: [UserProfile]

    @State private var appeared = false
    @State private var showNewJourney = false
    @State private var showPaywall = false
    @State private var showDynamicJourney = false
    @State private var showCouplesJourney = false
    @State private var showFamilyJourney = false
    @State private var showGiftJourney = false
    @State private var showReferral = false
    @State private var selectedTheme: JourneyTheme?

    private var profile: UserProfile? { profiles.first }
    private var isPremium: Bool { profile?.isPremium ?? false }
    private var activeJourney: Journey? { journeys.first }

    private let themeColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AJTheme.paddingLarge) {

                    // MARK: - Section 1: Active Journey Hero
                    activeJourneyHero
                        .padding(.horizontal)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.05), value: appeared)

                    // MARK: - Section 2: Journey Themes
                    journeyThemesSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.15), value: appeared)

                    // MARK: - Section 3: Create Your Own
                    createYourOwnSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.25), value: appeared)

                    // MARK: - Section 4: Seasonal Journeys
                    seasonalSection
                        .padding(.horizontal)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.35), value: appeared)

                    // MARK: - Section 5: Gift & Share
                    giftAndShareSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.45), value: appeared)

                    Spacer(minLength: AJTheme.paddingLarge)
                }
                .padding(.vertical)
            }
            .ajScreenBackground()
            .navigationTitle("Discover")
            .onAppear {
                withAnimation {
                    appeared = true
                }
            }
            .sheet(isPresented: $showNewJourney) {
                NewJourneyView()
            }
            .sheet(isPresented: $showPaywall) {
                PremiumPaywallView()
            }
            .sheet(isPresented: $showDynamicJourney) {
                DynamicJourneyView()
            }
            .sheet(isPresented: $showCouplesJourney) {
                CouplesJourneyView()
            }
            .sheet(isPresented: $showFamilyJourney) {
                FamilyJourneyView()
            }
            .sheet(isPresented: $showGiftJourney) {
                GiftJourneyView()
            }
            .sheet(isPresented: $showReferral) {
                ReferralView(userName: profile?.name ?? "Friend")
            }
        }
    }

    // MARK: - Section 1: Active Journey Hero

    @ViewBuilder
    private var activeJourneyHero: some View {
        if let journey = activeJourney {
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(journey.theme.color, default: .accentColor).opacity(0.12))
                            .frame(width: 52, height: 52)
                        Image(systemName: journey.theme.icon)
                            .font(.title3)
                            .foregroundStyle(Color(journey.theme.color, default: .accentColor))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(journey.title)
                            .font(AJTheme.subheadlineFont)
                            .foregroundStyle(AJTheme.primaryText)
                        Text("Day \(journey.currentDay) of \(journey.totalDays)")
                            .font(AJTheme.captionFont)
                            .foregroundStyle(AJTheme.secondaryText)
                    }

                    Spacer()
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AJTheme.sage.opacity(0.15))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AJTheme.sage)
                            .frame(width: geo.size.width * journey.progress, height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(Int(journey.progress * 100))% complete")
                        .font(AJTheme.captionFont)
                        .foregroundStyle(AJTheme.secondaryText)
                    Spacer()
                    Text("Continue on Today tab")
                        .font(.caption2.bold())
                        .foregroundStyle(AJTheme.sage)
                }
            }
            .ajCard()
        } else {
            VStack(spacing: 12) {
                Image(systemName: "book.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AJTheme.sage)

                Text("Find Your Journey")
                    .font(AJTheme.headlineFont)
                    .foregroundStyle(AJTheme.primaryText)

                Text("Explore 40-day guided themes to grow closer to God")
                    .font(AJTheme.captionFont)
                    .foregroundStyle(AJTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .ajCard()
        }
    }

    // MARK: - Section 2: Journey Themes

    private var journeyThemesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section header
            VStack(alignment: .leading, spacing: 4) {
                Text("Journey Themes")
                    .font(AJTheme.headlineFont)
                    .foregroundStyle(AJTheme.primaryText)
                Text("40 days of guided devotionals")
                    .font(AJTheme.captionFont)
                    .foregroundStyle(AJTheme.secondaryText)
            }
            .padding(.horizontal)

            LazyVGrid(columns: themeColumns, spacing: 12) {
                ForEach(JourneyTheme.allCases, id: \.self) { theme in
                    Button {
                        handleThemeTap(theme)
                    } label: {
                        DiscoverThemeCard(theme: theme, isPremium: theme.isPremium)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Section 3: Create Your Own

    private var createYourOwnSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Create Your Own")
                .font(AJTheme.headlineFont)
                .foregroundStyle(AJTheme.primaryText)
                .padding(.horizontal)

            // Custom AI Journey
            Button {
                if isPremium { showDynamicJourney = true } else { showPaywall = true }
            } label: {
                DiscoverFeatureCard(
                    icon: "wand.and.stars",
                    iconColor: .purple,
                    title: "Custom AI Journey",
                    subtitle: "Describe what you're going through — AI builds a 40-day journey for you",
                    showPremiumBadge: true
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            // Couples Journey
            Button {
                if isPremium { showCouplesJourney = true } else { showPaywall = true }
            } label: {
                DiscoverFeatureCard(
                    icon: "heart.circle.fill",
                    iconColor: .pink,
                    title: "Couples Journey",
                    subtitle: "Walk through 40 days of spiritual growth with your partner",
                    showPremiumBadge: true
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            // Family Journey
            Button {
                if isPremium { showFamilyJourney = true } else { showPaywall = true }
            } label: {
                DiscoverFeatureCard(
                    icon: "figure.2.and.child.holdinghands",
                    iconColor: .orange,
                    title: "Family Journey",
                    subtitle: "Age-appropriate devotionals for your whole family",
                    showPremiumBadge: true
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
    }

    // MARK: - Section 4: Seasonal Journeys

    private var seasonalSection: some View {
        NavigationLink {
            SeasonalJourneysBrowseView()
        } label: {
            if let season = SeasonalJourneyService.shared.currentActiveSeason() {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: 52, height: 52)
                        Image(systemName: season.icon)
                            .font(.title3)
                            .foregroundStyle(.orange)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(season.season.rawValue)
                                .font(.subheadline.bold())
                                .foregroundStyle(AJTheme.primaryText)

                            Capsule()
                                .fill(.green)
                                .frame(width: 6, height: 6)

                            Text("Live")
                                .font(.caption2.bold())
                                .foregroundStyle(.green)
                        }
                        Text("\(season.totalDays) days \u{2022} \(season.subtitle)")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .ajCard()
            } else {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: 52, height: 52)
                        Image(systemName: "calendar.badge.clock")
                            .font(.title3)
                            .foregroundStyle(.orange)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Seasonal Journeys")
                            .font(.subheadline.bold())
                            .foregroundStyle(AJTheme.primaryText)
                        Text("Advent, Lent, Holy Week, and more")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .ajCard()
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section 5: Gift & Share

    private var giftAndShareSection: some View {
        VStack(spacing: 12) {
            // Gift a Journey
            Button {
                if isPremium { showGiftJourney = true } else { showPaywall = true }
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: 52, height: 52)
                        Image(systemName: "gift.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Gift a Journey")
                                .font(.subheadline.bold())
                                .foregroundStyle(AJTheme.primaryText)

                            if !isPremium {
                                premiumBadge
                            }
                        }
                        Text("Send a friend a life-changing 40-day journey")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .ajCard()
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            // Invite Friends
            Button {
                showReferral = true
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.green.opacity(0.12))
                            .frame(width: 52, height: 52)
                        Image(systemName: "person.badge.plus")
                            .font(.title3)
                            .foregroundStyle(.green)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Invite Friends")
                            .font(.subheadline.bold())
                            .foregroundStyle(AJTheme.primaryText)
                        Text("Share your faith journey with someone you care about")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .ajCard()
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
    }

    // MARK: - Helpers

    private var premiumBadge: some View {
        Text("Premium")
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(AJTheme.gold))
    }

    private func handleThemeTap(_ theme: JourneyTheme) {
        if theme.isPremium && !isPremium {
            showPaywall = true
        } else {
            showNewJourney = true
        }
    }
}

// MARK: - Theme Card (grid item)

private struct DiscoverThemeCard: View {
    let theme: JourneyTheme
    let isPremium: Bool

    private var themeColor: Color {
        Color(theme.color, default: .accentColor)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(themeColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: theme.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(themeColor)
                }

                Spacer()

                if isPremium {
                    Text("Premium")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(AJTheme.gold))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(theme.rawValue)
                    .font(.subheadline.bold())
                    .foregroundStyle(AJTheme.primaryText)
                    .lineLimit(1)

                Text(theme.subtitle)
                    .font(.caption)
                    .foregroundStyle(AJTheme.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(AJTheme.paddingMedium)
        .background(
            RoundedRectangle(cornerRadius: AJTheme.cornerRadius)
                .fill(AJTheme.cardBackground)
                .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
        )
    }
}

// MARK: - Feature Card (Create Your Own items)

private struct DiscoverFeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let showPremiumBadge: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(AJTheme.primaryText)

                    if showPremiumBadge {
                        Text("Premium")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(AJTheme.gold))
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
            RoundedRectangle(cornerRadius: AJTheme.cornerRadius)
                .fill(AJTheme.cardBackground)
                .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    DiscoverView()
        .modelContainer(for: [Journey.self, UserProfile.self], inMemory: true)
}
