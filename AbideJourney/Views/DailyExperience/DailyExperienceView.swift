import SwiftUI
import SwiftData

struct DailyExperienceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(filter: #Predicate<Journey> { $0.isActive }) private var journeys: [Journey]
    @Query private var profiles: [UserProfile]
    @State private var viewModel = DailyExperienceViewModel()
    @State private var showingPremiumSheet = false
    @State private var showingCompletionSheet = false
    @State private var showingMilestoneSheet = false
    @State private var showingAdvancePrompt = false

    private var isPremium: Bool { profiles.first?.isPremium ?? false }

    var body: some View {
        NavigationStack {
            Group {
                if let day = viewModel.currentDay, let journey = viewModel.journey {
                    ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: AJTheme.paddingLarge) {
                            Color.clear
                                .frame(height: 0)
                                .id("scrollTop")

                            DayHeaderView(
                                dayNumber: day.dayNumber,
                                totalDays: journey.totalDays,
                                focusArea: day.focusArea,
                                progress: journey.progress
                            )

                            ScriptureCardView(
                                reference: day.scriptureReference,
                                text: day.scriptureText
                            )

                            DevotionalCardView(
                                title: day.devotionalTitle,
                                text: day.devotionalText,
                                isPremium: isPremium
                            )

                            ActionStepsCardView(
                                steps: $viewModel.actionSteps,
                                onToggle: { index in
                                    viewModel.toggleActionStep(at: index, context: modelContext)
                                }
                            )

                            ReflectionCardView(
                                prompt: day.reflectionPrompt,
                                onTapJournal: {
                                    viewModel.showingJournalSheet = true
                                }
                            )

                            if !day.prayerText.isEmpty {
                                PrayerCardView(
                                    prayerText: day.prayerText,
                                    hasPrayed: day.hasPrayed,
                                    onPrayed: {
                                        viewModel.markPrayed(context: modelContext)
                                    }
                                )
                            }

                            if isPremium {
                                PremiumFeatureHintsCard(dayNumber: day.dayNumber)
                            }

                            if !isPremium && day.dayNumber > 3 {
                                FreeUserUpgradeCard {
                                    showingPremiumSheet = true
                                }
                            }

                            if viewModel.dailyLimitReached {
                                DailyLimitReachedCard(isPremium: isPremium)
                                    .padding(.horizontal)
                                    .padding(.bottom, AJTheme.paddingXLarge)
                            } else {
                                Button {
                                    viewModel.showingCheckInSheet = true
                                } label: {
                                    HStack {
                                        Image(systemName: "checkmark.seal.fill")
                                            .accessibilityHidden(true)
                                        Text("Complete Day \(day.dayNumber)")
                                    }
                                }
                                .buttonStyle(AJPrimaryButtonStyle())
                                .padding(.horizontal)
                                .padding(.bottom, AJTheme.paddingXLarge)
                            }
                        }
                    }
                    .alert("Continue to Next Day?", isPresented: $showingAdvancePrompt) {
                        Button("Yes, Keep Going") {
                            withAnimation {
                                scrollProxy.scrollTo("scrollTop", anchor: .top)
                            }
                        }
                        Button("I'm Done for Now", role: .cancel) { }
                    } message: {
                        if let day = viewModel.currentDay {
                            Text("Great work! You can complete up to 3 days today. Ready to start Day \(day.dayNumber)?")
                        }
                    }
                    } // ScrollViewReader
                } else {
                    ContentUnavailableView(
                        "No Active Journey",
                        systemImage: "book.closed",
                        description: Text("Start a new journey from Settings to begin.")
                    )
                }
            }
            .navigationTitle("Today")
            .ajScreenBackground()
            .onAppear {
                viewModel.loadCurrentDay(from: journeys)
                viewModel.checkDailyLimit(isPremium: isPremium)
            }
            .sheet(isPresented: $viewModel.showingJournalSheet) {
                JournalEntrySheet(
                    journalText: $viewModel.journalText,
                    selectedMood: $viewModel.selectedMood,
                    isVoiceEntry: $viewModel.isVoiceJournalEntry,
                    prompt: viewModel.currentDay?.reflectionPrompt ?? ""
                )
            }
            .sheet(isPresented: $viewModel.showingCheckInSheet, onDismiss: {
                if isPremium && !viewModel.dailyLimitReached && !viewModel.journeyJustCompleted {
                    showingAdvancePrompt = true
                }
            }) {
                CheckInSheet { rating, note in
                    viewModel.submitCheckIn(rating: rating, note: note, context: modelContext)
                    viewModel.completeDay(rating: rating, isPremium: isPremium, context: modelContext)
                }
            }
            .sheet(isPresented: $showingPremiumSheet) {
                PremiumPaywallView()
            }
            .sheet(isPresented: $showingCompletionSheet) {
                JourneyCompletionView(
                    journey: viewModel.journey,
                    isPremium: isPremium,
                    onStartNewJourney: { showingPremiumSheet = true }
                )
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    viewModel.loadCurrentDay(from: journeys)
                    viewModel.checkDailyLimit(isPremium: isPremium)
                }
            }
            .onChange(of: viewModel.journeyJustCompleted) { _, completed in
                if completed {
                    showingCompletionSheet = true
                    viewModel.journeyJustCompleted = false
                }
            }
            .onChange(of: viewModel.milestoneDay) { _, day in
                if day != nil {
                    showingMilestoneSheet = true
                }
            }
            .sheet(isPresented: $showingMilestoneSheet, onDismiss: {
                viewModel.milestoneDay = nil
            }) {
                if let day = viewModel.milestoneDay, let journey = viewModel.journey {
                    MilestoneCelebrationView(
                        dayNumber: day,
                        journeyTitle: journey.title,
                        journeyTheme: journey.theme,
                        userName: profiles.first?.name ?? "Friend"
                    )
                }
            }
        }
    }
}

// MARK: - Day Header

struct DayHeaderView: View {
    let dayNumber: Int
    let totalDays: Int
    let focusArea: DiscipleshipArea
    let progress: Double

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day \(dayNumber)")
                        .font(AJTheme.titleFont)
                        .foregroundColor(AJTheme.primaryText)
                    HStack(spacing: 6) {
                        Image(systemName: focusArea.icon)
                            .accessibilityHidden(true)
                        Text(focusArea.rawValue)
                    }
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(AJTheme.secondaryText)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(AJTheme.sage.opacity(0.15), lineWidth: 6)
                        .frame(width: 60, height: 60)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(AJTheme.sage, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    Text("\(dayNumber)/\(totalDays)")
                        .font(.system(.caption2, design: .serif, weight: .bold))
                        .foregroundColor(AJTheme.primaryText)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Journey progress, day \(dayNumber) of \(totalDays), \(Int(progress * 100)) percent complete")
            }

            ProgressView(value: progress)
                .tint(AJTheme.sage)
        }
        .ajCard()
        .padding(.horizontal)
    }
}

// MARK: - Scripture Card

struct ScriptureCardView: View {
    let reference: String
    let text: String

    var body: some View {
        VStack(spacing: AJTheme.paddingMedium) {
            Image(systemName: "book.closed.fill")
                .font(.title2)
                .foregroundColor(AJTheme.gold)

            Text("\u{201C}\(text)\u{201D}")
                .font(AJTheme.scriptureFont)
                .foregroundColor(AJTheme.primaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text("— \(reference)")
                .font(.system(.caption, design: .serif, weight: .semibold))
                .foregroundColor(AJTheme.sage)
        }
        .ajCard()
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Scripture from \(reference): \(text)")
    }
}

// MARK: - Devotional Card

struct DevotionalCardView: View {
    let title: String
    let text: String
    var isPremium: Bool = false
    @State private var isExpanded = false
    @State private var tts = TextToSpeechService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .foregroundStyle(AJTheme.gold)
                    .accessibilityHidden(true)
                Text("Devotional")
                    .font(AJTheme.subheadlineFont)
                    .foregroundColor(AJTheme.primaryText)
                Spacer()

                if isPremium {
                    Button {
                        if tts.isSpeaking || tts.isPaused {
                            tts.togglePlayPause()
                        } else {
                            tts.speak("\(title). \(text)")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: tts.isSpeaking ? "pause.fill" : (tts.isPaused ? "play.fill" : "speaker.wave.2.fill"))
                                .font(.caption)
                            Text(tts.isSpeaking ? "Pause" : (tts.isPaused ? "Resume" : "Listen"))
                                .font(.system(.caption, design: .serif))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(AJTheme.gold.opacity(0.12))
                        )
                        .foregroundStyle(AJTheme.gold)
                    }
                    .accessibilityLabel(tts.isSpeaking ? "Pause devotional audio" : "Listen to devotional")
                }
            }

            Text(title)
                .font(.system(.title3, design: .serif, weight: .bold))
                .foregroundColor(AJTheme.primaryText)

            Text(text)
                .font(AJTheme.bodyFont)
                .foregroundColor(AJTheme.primaryText)
                .lineSpacing(4)
                .lineLimit(isExpanded ? nil : 4)

            if !isExpanded {
                Button("Read more") {
                    withAnimation { isExpanded = true }
                }
                .font(.system(.subheadline, design: .serif, weight: .semibold))
                .foregroundColor(AJTheme.sage)
            }
        }
        .ajCard()
        .padding(.horizontal)
        .onDisappear {
            tts.stop()
        }
    }
}

// MARK: - Action Steps Card

struct ActionStepsCardView: View {
    @Binding var steps: [ActionStep]
    let onToggle: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundStyle(AJTheme.success)
                    .accessibilityHidden(true)
                Text("Action Steps")
                    .font(AJTheme.subheadlineFont)
                    .foregroundColor(AJTheme.primaryText)
                Spacer()
                Text("\(steps.filter(\.isCompleted).count)/\(steps.count)")
                    .font(AJTheme.captionFont)
                    .foregroundStyle(AJTheme.secondaryText)
            }

            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                Button {
                    onToggle(index)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(step.isCompleted ? AJTheme.success : AJTheme.secondaryText)
                            .font(.title3)

                        Text(step.text)
                            .font(AJTheme.bodyFont)
                            .strikethrough(step.isCompleted)
                            .foregroundStyle(step.isCompleted ? AJTheme.secondaryText : AJTheme.primaryText)
                            .multilineTextAlignment(.leading)

                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(step.text)
                .accessibilityValue(step.isCompleted ? "Completed" : "Not completed")
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Double tap to toggle completion")
            }
        }
        .ajCard()
        .padding(.horizontal)
    }
}

// MARK: - Reflection Card

struct ReflectionCardView: View {
    let prompt: String
    let onTapJournal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pencil.and.outline")
                    .foregroundStyle(AJTheme.sandstone)
                    .accessibilityHidden(true)
                Text("Reflection")
                    .font(AJTheme.subheadlineFont)
                    .foregroundColor(AJTheme.primaryText)
                Spacer()
            }

            Text(prompt)
                .font(AJTheme.scriptureFont)
                .foregroundColor(AJTheme.primaryText)
                .lineSpacing(4)

            Button {
                onTapJournal()
            } label: {
                HStack {
                    Image(systemName: "square.and.pencil")
                        .accessibilityHidden(true)
                    Text("Write in Journal")
                }
            }
            .buttonStyle(AJSecondaryButtonStyle())
        }
        .ajCard()
        .padding(.horizontal)
    }
}

// MARK: - Prayer Card

struct PrayerCardView: View {
    let prayerText: String
    let hasPrayed: Bool
    let onPrayed: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "hands.sparkles.fill")
                    .foregroundStyle(AJTheme.gold)
                    .accessibilityHidden(true)
                Text("Prayer")
                    .font(AJTheme.subheadlineFont)
                    .foregroundColor(AJTheme.primaryText)
                Spacer()
                if hasPrayed {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AJTheme.success)
                        Text("Prayed")
                            .font(AJTheme.captionFont)
                            .foregroundStyle(AJTheme.success)
                    }
                }
            }

            Text("Pray this out loud or silently in your heart:")
                .font(AJTheme.captionFont)
                .foregroundStyle(AJTheme.secondaryText)

            Text(prayerText)
                .font(.system(.body, design: .serif))
                .foregroundColor(AJTheme.primaryText)
                .lineSpacing(4)
                .italic()
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: AJTheme.cornerRadiusSmall)
                        .fill(AJTheme.cream.opacity(0.5))
                )

            if !hasPrayed {
                Button {
                    onPrayed()
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .accessibilityHidden(true)
                        Text("I've Prayed")
                    }
                    .font(.system(.subheadline, design: .serif, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AJTheme.sage)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AJTheme.cornerRadius))
                }
            }
        }
        .ajCard()
        .padding(.horizontal)
    }
}

// MARK: - Daily Limit Reached Card

struct DailyLimitReachedCard: View {
    let isPremium: Bool

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 36))
                .foregroundStyle(AJTheme.sageDark)

            Text("You've done great today!")
                .font(AJTheme.subheadlineFont)
                .foregroundColor(AJTheme.primaryText)

            Text("This journey is meant to be savored — one day at a time. Come back tomorrow and pick up right where you left off.")
                .font(AJTheme.bodyFont)
                .foregroundStyle(AJTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            if !isPremium {
                Text("Premium members can complete up to 3 days per day.")
                    .font(AJTheme.captionFont)
                    .foregroundStyle(AJTheme.gold)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AJTheme.cornerRadius)
                .fill(AJTheme.sage.opacity(0.08))
        )
    }
}

// MARK: - Free User Upgrade Card

struct FreeUserUpgradeCard: View {
    let onTap: () -> Void

    private let perks = [
        ("paintpalette.fill", "Deep-Dive Themes"),
        ("mic.fill", "Voice Journaling"),
        ("wand.and.stars", "Custom Journeys"),
        ("heart.circle.fill", "Couples Journey"),
    ]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundStyle(AJTheme.gold)
                Text("Go Deeper with Premium")
                    .font(.system(.subheadline, design: .serif, weight: .semibold))
                    .foregroundColor(AJTheme.primaryText)
                Spacer()
            }

            HStack(spacing: 16) {
                ForEach(perks, id: \.0) { icon, label in
                    VStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.body)
                            .foregroundStyle(AJTheme.sage)
                        Text(label)
                            .font(.system(.caption2, design: .serif))
                            .foregroundStyle(AJTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Button {
                onTap()
            } label: {
                Text("Upgrade to Premium")
            }
            .buttonStyle(AJPremiumButtonStyle())
        }
        .ajCard()
        .padding(.horizontal)
    }
}

// MARK: - Premium Feature Hints Card

struct PremiumFeatureHintsCard: View {
    let dayNumber: Int

    private var hint: (icon: String, color: Color, title: String, subtitle: String)? {
        switch dayNumber {
        case 1...3:
            return ("mic.fill", AJTheme.sandstone, "Try Voice Journaling", "Tap the mic button when journaling to speak your reflections instead of typing.")
        case 4...7:
            return ("map.fill", AJTheme.sage, "Explore Your Faith Map", "Check the Progress tab to see your spiritual growth visualized over time.")
        case 8...14:
            return ("person.2.fill", AJTheme.success, "Invite an Accountability Partner", "Go to Settings to invite a friend to walk alongside you on this journey.")
        case 15...21:
            return ("heart.circle.fill", AJTheme.sandstone, "Try a Couples Journey", "Walk through 40 days with your partner — find it in Settings under Journey.")
        case 22...30:
            return ("wand.and.stars", AJTheme.gold, "Create a Custom Journey", "Describe what you're going through and we'll build a journey just for you. Find it in Settings.")
        case 31...40:
            return ("gift.fill", AJTheme.gold, "Gift a Journey", "Know someone who could use encouragement? Send them a journey from Settings.")
        default:
            return nil
        }
    }

    var body: some View {
        if let hint {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(hint.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: hint.icon)
                        .font(.body)
                        .foregroundStyle(hint.color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(hint.title)
                        .font(.system(.subheadline, design: .serif, weight: .semibold))
                        .foregroundColor(AJTheme.primaryText)
                    Text(hint.subtitle)
                        .font(AJTheme.captionFont)
                        .foregroundStyle(AJTheme.secondaryText)
                        .lineSpacing(2)
                }

                Spacer(minLength: 0)
            }
            .ajCard()
            .padding(.horizontal)
        }
    }
}

#Preview {
    DailyExperienceView()
        .modelContainer(for: Journey.self, inMemory: true)
}
