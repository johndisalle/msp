import SwiftUI
import SwiftData

// MARK: - Seasonal Banner (auto-appears on Today tab)

struct SeasonalJourneyBanner: View {
    let season: SeasonalJourney
    let onStart: () -> Void
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var shimmer = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Gradient background
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: season.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Shimmer overlay
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.08), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmer ? 300 : -300)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: false), value: shimmer)

                VStack(spacing: 12) {
                    HStack {
                        // Season badge
                        HStack(spacing: 6) {
                            Image(systemName: season.icon)
                                .font(.caption)
                            Text(season.season.rawValue.uppercased())
                                .font(.caption2.bold())
                                .tracking(1.5)
                        }
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.white.opacity(0.15)))

                        Spacer()

                        // Dismiss
                        Button {
                            withAnimation(.spring()) {
                                onDismiss()
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(6)
                                .background(Circle().fill(.white.opacity(0.1)))
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(season.title)
                            .font(.system(.headline, design: .serif, weight: .bold))
                            .foregroundStyle(.white)

                        Text(season.subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.75))
                            .lineLimit(2)

                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                Text("\(season.totalDays) days")
                                    .font(.caption2.bold())
                            }
                            .foregroundStyle(.white.opacity(0.7))

                            if season.isCurrentlyActive {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(.green)
                                        .frame(width: 6, height: 6)
                                    Text("Active Now")
                                        .font(.caption2.bold())
                                }
                                .foregroundStyle(.green)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        onStart()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.caption)
                            Text("Begin \(season.season.rawValue) Journey")
                                .font(.subheadline.bold())
                        }
                        .foregroundStyle(season.gradient.first ?? .purple)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.white)
                        )
                    }
                }
                .padding(16)
            }
            .frame(height: 200)
        }
        .padding(.horizontal)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 30)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
            shimmer = true
        }
    }
}

// MARK: - Seasonal Journey Detail View

struct SeasonalJourneyDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let season: SeasonalJourney

    @State private var appeared = false
    @State private var isStarting = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: season.gradient + [Color(red: 0.05, green: 0.05, blue: 0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: season.icon)
                            .font(.system(size: 56))
                            .foregroundStyle(.white)
                            .shadow(color: .white.opacity(0.3), radius: 20)
                            .scaleEffect(appeared ? 1 : 0.5)

                        Text(season.title)
                            .font(.system(.title, design: .serif, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text(season.season.tagline)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))

                        HStack(spacing: 20) {
                            StatPill(icon: "calendar", value: "\(season.totalDays)", label: "Days")
                            StatPill(icon: "book.fill", value: "\(season.themes.count)", label: "Themes")
                            if season.isCurrentlyActive {
                                StatPill(icon: "circle.fill", value: "Live", label: "Now", color: .green)
                            }
                        }
                    }
                    .padding(.top, 40)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.6), value: appeared)

                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About This Journey")
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(.white)

                        Text(season.description)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                            .lineSpacing(4)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white.opacity(0.08))
                    )
                    .padding(.horizontal)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.15), value: appeared)

                    // Themes preview
                    VStack(alignment: .leading, spacing: 14) {
                        Text("What You'll Explore")
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(.white)

                        FlowLayout(spacing: 8) {
                            ForEach(season.themes, id: \.self) { theme in
                                Text(theme)
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(.white.opacity(0.12))
                                            .overlay(
                                                Capsule()
                                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white.opacity(0.08))
                    )
                    .padding(.horizontal)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.25), value: appeared)

                    // Sample day preview
                    let sample = SeasonalJourneyService.shared.generateDayContent(for: season, dayNumber: 1)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preview: Day 1")
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(.white)

                        Text("\u{201C}\(sample.scripture.prefix(120))...\u{201D}")
                            .font(.system(.body, design: .serif).italic())
                            .foregroundStyle(.white.opacity(0.8))
                            .lineSpacing(3)

                        Text("— \(sample.scriptureRef)")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.35), value: appeared)

                    // Start button
                    Button {
                        startSeasonalJourney()
                    } label: {
                        HStack(spacing: 8) {
                            if isStarting {
                                ProgressView()
                                    .tint(season.gradient.first ?? .purple)
                            } else {
                                Image(systemName: "play.fill")
                            }
                            Text(isStarting ? "Creating Your Journey..." : "Start \(season.season.rawValue) Journey")
                                .font(.headline)
                        }
                        .foregroundStyle(season.gradient.first ?? .purple)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.white)
                        )
                        .shadow(color: .white.opacity(0.2), radius: 12)
                    }
                    .disabled(isStarting)
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.45), value: appeared)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close") { dismiss() }
                    .foregroundStyle(.white)
            }
        }
        .onAppear {
            withAnimation { appeared = true }
        }
    }

    private func startSeasonalJourney() {
        isStarting = true

        // Create the journey
        let journey = Journey(
            title: season.title,
            subtitle: season.subtitle,
            totalDays: season.totalDays,
            theme: .spiritualGrowth,
            focusAreas: DiscipleshipArea.allCases
        )

        modelContext.insert(journey)

        // Generate days
        var days: [JourneyDay] = []
        for dayNum in 1...season.totalDays {
            let content = SeasonalJourneyService.shared.generateDayContent(for: season, dayNumber: dayNum)
            let day = JourneyDay(
                dayNumber: dayNum,
                scriptureReference: content.scriptureRef,
                scriptureText: content.scripture,
                devotionalTitle: content.title,
                devotionalText: content.devotional,
                prayerText: content.prayer,
                reflectionPrompt: "How does today's theme speak to where you are in your spiritual journey right now?",
                focusArea: DiscipleshipArea.allCases[(dayNum - 1) % DiscipleshipArea.allCases.count],
                theme: .spiritualGrowth,
                actionSteps: [
                    ActionStep(text: "Read today's Scripture passage slowly, twice"),
                    ActionStep(text: "Spend 5 minutes in silent reflection"),
                    ActionStep(text: "Pray the guided prayer aloud")
                ]
            )
            day.journey = journey
            days.append(day)
            modelContext.insert(day)
        }

        journey.days = days

        do {
            try modelContext.save()
            dismiss()
        } catch {
            isStarting = false
        }
    }
}

// MARK: - Seasonal Journeys Browse View

struct SeasonalJourneysBrowseView: View {
    @State private var appeared = false
    private let service = SeasonalJourneyService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Active seasons first
                let active = service.allSeasons.filter { $0.isCurrentlyActive }
                if !active.isEmpty {
                    SectionHeader(title: "Available Now", icon: "circle.fill", color: .green)

                    ForEach(active) { season in
                        NavigationLink {
                            SeasonalJourneyDetailView(season: season)
                        } label: {
                            SeasonBrowseCard(season: season, isActive: true)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Upcoming
                let upcoming = service.allSeasons
                    .filter { !$0.isCurrentlyActive }
                    .sorted { ($0.daysUntilStart ?? 999) < ($1.daysUntilStart ?? 999) }

                if !upcoming.isEmpty {
                    SectionHeader(title: "Coming Soon", icon: "calendar.badge.clock", color: AJTheme.gold)

                    ForEach(upcoming) { season in
                        NavigationLink {
                            SeasonalJourneyDetailView(season: season)
                        } label: {
                            SeasonBrowseCard(season: season, isActive: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .ajScreenBackground()
        .navigationTitle("Seasonal Journeys")
    }
}

// MARK: - Supporting Views

private struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = .white

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(value)
                    .font(.caption.bold())
            }
            .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(color.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }
}

private struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(title)
                .font(.system(.subheadline, design: .serif, weight: .bold))
                .foregroundStyle(AJTheme.primaryText)
            Spacer()
        }
        .padding(.top, 8)
    }
}

private struct SeasonBrowseCard: View {
    let season: SeasonalJourney
    let isActive: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: season.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                Image(systemName: season.icon)
                    .font(.title3)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(season.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(AJTheme.primaryText)
                        .lineLimit(1)

                    if isActive {
                        Text("LIVE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.green))
                    }
                }

                Text(season.subtitle)
                    .font(.caption)
                    .foregroundStyle(AJTheme.secondaryText)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        Image(systemName: "calendar")
                            .font(.system(size: 9))
                        Text("\(season.totalDays) days")
                            .font(.caption2)
                    }
                    .foregroundStyle(AJTheme.secondaryText)

                    if let daysUntil = season.daysUntilStart, !isActive {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                            Text("Starts in \(daysUntil) days")
                                .font(.caption2)
                        }
                        .foregroundStyle(AJTheme.gold)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AJTheme.cardBackground)
                .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
        )
    }
}

#Preview {
    NavigationStack {
        SeasonalJourneysBrowseView()
    }
}
