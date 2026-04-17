import SwiftUI
import SwiftData

struct DailyExperienceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(filter: #Predicate<Journey> { $0.isActive }) private var journeys: [Journey]
    @Query private var profiles: [UserProfile]
    @State private var viewModel = DailyExperienceViewModel()
    @State private var showingPremiumSheet = false
    @State private var showingSmartPaywall = false
    @State private var showingCompletionSheet = false
    @State private var showingMilestoneSheet = false
    @State private var showingAdvancePrompt = false
    @State private var showingListenMode = false
    @State private var showingSeasonalDetail = false
    @State private var activeSeason: SeasonalJourney?
    @State private var cardsAppeared = false
    @State private var showingSettings = false
    @State private var showingNewJourneyFromEmpty = false
    @State private var showPostCompletionSuggestions = false

    private var isPremium: Bool { profiles.first?.isPremium ?? false }

    var body: some View {
        NavigationStack {
            Group {
                if let day = viewModel.currentDay, let journey = viewModel.journey {
                    ScrollViewReader { scrollProxy in
                    ZStack {
                    ScrollView {
                        VStack(spacing: AJTheme.paddingLarge) {
                            Color.clear
                                .frame(height: 0)
                                .id("scrollTop")

                            // Compact progress strip
                            if let journey = viewModel.journey {
                                ProgressStripView(journey: journey, dayNumber: day.dayNumber)
                                    .padding(.horizontal)
                            }

                            DayHeaderView(
                                dayNumber: day.dayNumber,
                                totalDays: journey.totalDays,
                                focusArea: day.focusArea,
                                journeyTitle: journey.title,
                                progress: journey.progress
                            )

                            // Seasonal Journey banner (hide if already in this seasonal journey)
                            if let season = activeSeason, journey.title != season.title {
                                SeasonalJourneyBanner(
                                    season: season,
                                    onStart: { showingSeasonalDetail = true },
                                    onDismiss: {
                                        SeasonalJourneyService.shared.dismiss(season)
                                        withAnimation { activeSeason = nil }
                                    }
                                )
                            }

                            // Couples Journey banner
                            if journey.isCouple, let partnerName = journey.partnerName {
                                CouplesJourneyBanner(
                                    partnerName: partnerName,
                                    dayNumber: day.dayNumber,
                                    totalDays: journey.totalDays
                                )
                            }

                            ScriptureCardView(
                                reference: day.scriptureReference,
                                text: day.scriptureText
                            )

                            DevotionalCardView(
                                title: day.devotionalTitle,
                                text: day.devotionalText,
                                isPremium: isPremium,
                                onListenTapped: {
                                    showingListenMode = true
                                },
                                onPremiumTapped: {
                                    showingPremiumSheet = true
                                }
                            )
                            .opacity(cardsAppeared ? 1 : 0)
                            .offset(y: cardsAppeared ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.1), value: cardsAppeared)

                            ActionStepsCardView(
                                steps: $viewModel.actionSteps,
                                onToggle: { index in
                                    viewModel.toggleActionStep(at: index, context: modelContext)
                                }
                            )
                            .opacity(cardsAppeared ? 1 : 0)
                            .offset(y: cardsAppeared ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.2), value: cardsAppeared)

                            ReflectionCardView(
                                prompt: day.reflectionPrompt,
                                onTapJournal: {
                                    viewModel.showingJournalSheet = true
                                }
                            )
                            .opacity(cardsAppeared ? 1 : 0)
                            .offset(y: cardsAppeared ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.3), value: cardsAppeared)

                            if !day.prayerText.isEmpty {
                                PrayerCardView(
                                    prayerText: day.prayerText,
                                    hasPrayed: day.hasPrayed,
                                    onPrayed: {
                                        viewModel.markPrayed(context: modelContext)
                                    }
                                )
                                .opacity(cardsAppeared ? 1 : 0)
                                .offset(y: cardsAppeared ? 0 : 20)
                                .animation(.easeOut(duration: 0.5).delay(0.4), value: cardsAppeared)
                            }

                            if isPremium {
                                PremiumFeatureHintsCard(dayNumber: day.dayNumber)
                            }

                            if !isPremium && day.dayNumber > 3 {
                                FreeUserUpgradeCard {
                                    showingPremiumSheet = true
                                }
                            }

                            if showPostCompletionSuggestions {
                                PostCompletionSuggestionsCard()
                                    .padding(.horizontal)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }

                            if viewModel.dailyLimitReached {
                                DailyLimitReachedCard(isPremium: isPremium) {
                                    showingPremiumSheet = true
                                }
                                    .padding(.horizontal)
                                    .padding(.bottom, AJTheme.paddingXLarge)
                            } else {
                                Button {
                                    viewModel.showingCheckInSheet = true
                                } label: {
                                    HStack {
                                        Image(systemName: "checkmark.seal.fill")
                                            .accessibilityHidden(true)
                                        Text("I’ve Abided — Day \(day.dayNumber)")
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
                    // Badge toast overlay
                    if let badge = viewModel.newBadge {
                        VStack {
                            NewBadgeToast(badge: badge) {
                                viewModel.newBadge = nil
                            }
                            Spacer()
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Confetti overlay
                    if viewModel.showConfetti {
                        ConfettiView()
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                    withAnimation { viewModel.showConfetti = false }
                                }
                            }
                    }
                    } // ZStack
                    } // ScrollViewReader
                } else {
                    ScrollView {
                        VStack(spacing: AJTheme.paddingLarge) {
                            Spacer().frame(height: 40)

                            // Greeting
                            VStack(spacing: 8) {
                                Text(greetingText)
                                    .font(AJTheme.headlineFont)
                                    .foregroundStyle(AJTheme.primaryText)

                                Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                                    .font(.system(.subheadline, design: .serif))
                                    .foregroundStyle(AJTheme.secondaryText)
                            }

                            // Hero verse
                            VStack(spacing: 12) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(AJTheme.sage.opacity(0.6))

                                Text("\u{201C}Your word is a lamp to my feet and a light to my path.\u{201D}")
                                    .font(AJTheme.scriptureFont)
                                    .foregroundStyle(AJTheme.primaryText)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .padding(.horizontal, AJTheme.paddingLarge)

                                Text("— Psalm 119:105")
                                    .font(.system(.caption, design: .serif, weight: .semibold))
                                    .foregroundStyle(AJTheme.gold)
                            }
                            .padding(.vertical, AJTheme.paddingLarge)

                            // Begin CTA
                            Button {
                                // Switch to Discover tab - for now, show NewJourneyView
                                showingNewJourneyFromEmpty = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Begin Your Journey")
                                }
                            }
                            .buttonStyle(AJPrimaryButtonStyle())
                            .padding(.horizontal, AJTheme.paddingXLarge)

                            // Quick access cards
                            VStack(spacing: 4) {
                                Text("or explore while you decide")
                                    .font(AJTheme.captionFont)
                                    .foregroundStyle(AJTheme.secondaryText)
                            }
                            .padding(.top, 8)

                            HStack(spacing: 12) {
                                NavigationLink {
                                    BreathingMeditationView()
                                } label: {
                                    quickAccessCard(icon: "wind", color: .teal, title: "Breathe")
                                }
                                .buttonStyle(.plain)

                                NavigationLink {
                                    PrayerWallView()
                                } label: {
                                    quickAccessCard(icon: "hands.sparkles.fill", color: .blue, title: "Pray")
                                }
                                .buttonStyle(.plain)

                                NavigationLink {
                                    ScriptureMemoryView()
                                } label: {
                                    quickAccessCard(icon: "brain.head.profile", color: .purple, title: "Memorize")
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal)

                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(AJTheme.secondaryText)
                    }
                    .accessibilityLabel("Settings")
                }
                if viewModel.currentDay != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 16) {
                            if isPremium {
                                Button {
                                    showingListenMode = true
                                } label: {
                                    Image(systemName: "headphones.circle.fill")
                                        .foregroundStyle(AJTheme.sage)
                                }
                                .accessibilityLabel("Listen to today's devotional")
                            }

                            Button {
                                viewModel.toggleBookmark(context: modelContext)
                            } label: {
                                Image(systemName: viewModel.currentDay?.isBookmarked == true ? "bookmark.fill" : "bookmark")
                                    .foregroundStyle(viewModel.currentDay?.isBookmarked == true ? AJTheme.gold : AJTheme.secondaryText)
                            }
                            .accessibilityLabel(viewModel.currentDay?.isBookmarked == true ? "Remove bookmark" : "Bookmark this day")

                            NavigationLink {
                                BookmarkedDaysView()
                            } label: {
                                Image(systemName: "bookmark.square")
                                    .foregroundStyle(AJTheme.sage)
                            }
                            .accessibilityLabel("View bookmarked days")
                        }
                    }
                }
            }
            .ajScreenBackground()
            .onAppear {
                viewModel.loadCurrentDay(from: journeys)
                viewModel.checkDailyLimit(isPremium: isPremium)
                activeSeason = SeasonalJourneyService.shared.currentActiveSeason()
                cardsAppeared = false
                withAnimation {
                    cardsAppeared = true
                }
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
                withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                    showPostCompletionSuggestions = true
                }
            }) {
                CheckInSheet { rating, note in
                    viewModel.submitCheckIn(rating: rating, note: note, context: modelContext)
                    viewModel.completeDay(rating: rating, isPremium: isPremium, context: modelContext)
                    if let dayNumber = viewModel.currentDay?.dayNumber, dayNumber == 7, !isPremium {
                        let key = "paywall_week_one_shown"
                        if !UserDefaults.standard.bool(forKey: key) {
                            UserDefaults.standard.set(true, forKey: key)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                showingPremiumSheet = true
                            }
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showingListenMode) {
                if let day = viewModel.currentDay {
                    ListenModeView(
                        scriptureRef: day.scriptureReference,
                        scriptureText: day.scriptureText,
                        devotionalTitle: day.devotionalTitle,
                        devotionalText: day.devotionalText,
                        prayerText: day.prayerText,
                        dayNumber: day.dayNumber,
                        focusArea: day.focusArea.rawValue
                    )
                }
            }
            .sheet(isPresented: $showingSeasonalDetail) {
                if let season = activeSeason {
                    NavigationStack {
                        SeasonalJourneyDetailView(season: season)
                    }
                }
            }
            .sheet(isPresented: $showingPremiumSheet) {
                PremiumPaywallView()
            }
            .sheet(isPresented: $showingNewJourneyFromEmpty) {
                NewJourneyView()
            }
            .sheet(isPresented: $showingSmartPaywall) {
                PremiumPaywallView()
            }
            .onChange(of: viewModel.shouldShowSmartPaywall) { _, show in
                if show {
                    showingSmartPaywall = true
                    viewModel.shouldShowSmartPaywall = false
                }
            }
            .sheet(isPresented: $showingCompletionSheet) {
                JourneyCompletionView(
                    journey: viewModel.journey,
                    isPremium: isPremium,
                    onStartNewJourney: { showingPremiumSheet = true }
                )
            }
            .alert("Save Error", isPresented: Binding(
                get: { viewModel.saveError != nil },
                set: { if !$0 { viewModel.saveError = nil } }
            )) {
                Button("OK") { viewModel.saveError = nil }
            } message: {
                Text(viewModel.saveError ?? "")
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    viewModel.loadCurrentDay(from: journeys)
                    viewModel.checkDailyLimit(isPremium: isPremium)
                }
            }
            .onChange(of: journeys) {
                viewModel.loadCurrentDay(from: journeys)
                viewModel.checkDailyLimit(isPremium: isPremium)
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

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = profiles.first?.name ?? "Friend"
        switch hour {
        case 5..<12: return "Good morning, \(name)"
        case 12..<17: return "Good afternoon, \(name)"
        default: return "Good evening, \(name)"
        }
    }

    private func quickAccessCard(icon: String, color: Color, title: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.system(.caption, design: .serif, weight: .medium))
                .foregroundStyle(AJTheme.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AJTheme.paddingMedium)
        .background(
            RoundedRectangle(cornerRadius: AJTheme.cornerRadius)
                .fill(AJTheme.cardBackground)
                .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
        )
    }
}

// MARK: - Couples Journey Banner

struct CouplesJourneyBanner: View {
    let partnerName: String
    let dayNumber: Int
    let totalDays: Int
    @State private var showingShareInvite = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AJTheme.gold.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "heart.fill")
                        .font(.body)
                        .foregroundStyle(AJTheme.gold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Couples Journey with \(partnerName)")
                        .font(.subheadline.bold())
                        .foregroundStyle(AJTheme.primaryText)
                    Text("Day \(dayNumber) of \(totalDays) together")
                        .font(.caption)
                        .foregroundStyle(AJTheme.secondaryText)
                }

                Spacer()
            }

            // Progress together
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.caption2)
                        .foregroundStyle(AJTheme.sage)
                    Text("You")
                        .font(.caption2)
                        .foregroundStyle(AJTheme.secondaryText)
                    Text("Day \(dayNumber)")
                        .font(.caption2.bold())
                        .foregroundStyle(AJTheme.sage)
                }

                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(AJTheme.gold)
                    Text(partnerName)
                        .font(.caption2)
                        .foregroundStyle(AJTheme.secondaryText)
                    Text("Invited")
                        .font(.caption2.bold())
                        .foregroundStyle(AJTheme.gold)
                }

                Spacer()
            }

            Button {
                showingShareInvite = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "paperplane.fill")
                        .font(.caption)
                    Text("Send \(partnerName) a Reminder")
                        .font(.caption.bold())
                }
                .foregroundStyle(AJTheme.gold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AJTheme.gold.opacity(0.1))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AJTheme.cardBackground)
                .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AJTheme.gold.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
        .sheet(isPresented: $showingShareInvite) {
            let message = "Hey \(partnerName)! I'm on Day \(dayNumber) of our couples journey. Don't forget to open Abide Journey today so we can grow in faith together!"
            ShareSheet(items: [message])
        }
    }
}

// MARK: - Day Header

struct DayHeaderView: View {
    let dayNumber: Int
    let totalDays: Int
    let focusArea: DiscipleshipArea
    var journeyTitle: String = ""
    let progress: Double
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day \(dayNumber)")
                        .font(AJTheme.titleFont)
                        .foregroundColor(AJTheme.primaryText)
                        .scaleEffect(appeared ? 1 : 0.9, anchor: .leading)
                        .opacity(appeared ? 1 : 0)
                    HStack(spacing: 6) {
                        Image(systemName: focusArea.icon)
                            .accessibilityHidden(true)
                        Text(journeyTitle.isEmpty ? focusArea.rawValue : journeyTitle)
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
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }
}

// MARK: - Scripture Card

struct ScriptureCardView: View {
    let reference: String
    let text: String
    @State private var appeared = false
    @State private var showShareSheet = false
    @State private var showVerseCard = false
    @State private var memorizeAdded = false

    private var shareText: String {
        "\u{201C}\(text)\u{201D}\n— \(reference)\n\nAbide Journey"
    }

    var body: some View {
        VStack(spacing: AJTheme.paddingMedium) {
            HStack {
                Spacer()
                Image(systemName: "book.closed.fill")
                    .font(.title2)
                    .foregroundColor(AJTheme.gold)
                Spacer()
            }
            .overlay(alignment: .trailing) {
                HStack(spacing: 4) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showVerseCard = true
                    } label: {
                        Image(systemName: "photo.artframe")
                            .font(.subheadline)
                            .foregroundStyle(AJTheme.gold)
                            .padding(8)
                    }
                    .accessibilityLabel("Create verse card")

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        AchievementService.shared.recordVerseShare()
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.subheadline)
                            .foregroundStyle(AJTheme.sage)
                            .padding(8)
                    }
                    .accessibilityLabel("Share this verse")
                }
            }
            .overlay(alignment: .leading) {
                Button {
                    ScriptureMemoryService.shared.addVerse(reference: reference, text: text)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation { memorizeAdded = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { memorizeAdded = false }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: memorizeAdded ? "checkmark" : "brain.head.profile")
                            .font(.caption)
                        Text(memorizeAdded ? "Saved" : "Memorize")
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(memorizeAdded ? AJTheme.success : AJTheme.sandstone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(memorizeAdded ? AJTheme.success.opacity(0.12) : AJTheme.sandstone.opacity(0.12))
                    )
                }
                .accessibilityLabel("Save verse for memorization")
            }

            Text("\u{201C}\(text)\u{201D}")
                .font(AJTheme.scriptureFont)
                .foregroundColor(AJTheme.primaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)

            Text("— \(reference)")
                .font(.system(.caption, design: .serif, weight: .semibold))
                .foregroundColor(AJTheme.sage)
                .opacity(appeared ? 1 : 0)
        }
        .ajCard()
        .padding(.horizontal)
        .background(
            GeometryReader { geo in
                let midY = geo.frame(in: .global).midY
                let screenMid = UIScreen.main.bounds.height / 2
                let offset = (midY - screenMid) * 0.04
                AJTheme.goldLight.opacity(0.15)
                    .clipShape(RoundedRectangle(cornerRadius: AJTheme.cornerRadius))
                    .offset(y: offset)
                    .padding(.horizontal)
            }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Scripture from \(reference): \(text)")
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
        .sheet(isPresented: $showVerseCard) {
            VerseCardEditorView(reference: reference, text: text)
        }
    }
}

// MARK: - Devotional Card

struct DevotionalCardView: View {
    let title: String
    let text: String
    var isPremium: Bool = false
    var onListenTapped: (() -> Void)? = nil
    var onPremiumTapped: (() -> Void)? = nil
    @State private var isExpanded = false

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
                .accessibilityLabel("Read full devotional")
                .accessibilityHint("Double tap to expand the devotional text")
            }

            // Listen Mode teaser
            if let onListen = onListenTapped {
                Divider()
                    .padding(.vertical, 4)

                Button {
                    if isPremium {
                        onListen()
                    } else {
                        onPremiumTapped?()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "waveform")
                            .font(.caption)
                            .foregroundStyle(isPremium ? AJTheme.sage : AJTheme.secondaryText)
                        Text(isPremium ? "Listen to this devotional" : "Listen Mode")
                            .font(.system(.caption, design: .serif, weight: .semibold))
                            .foregroundStyle(isPremium ? AJTheme.sage : AJTheme.secondaryText)
                        Spacer()
                        if isPremium {
                            Image(systemName: "play.circle.fill")
                                .font(.title3)
                                .foregroundStyle(AJTheme.sage)
                        } else {
                            Text("Premium")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(AJTheme.gold))
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: AJTheme.cornerRadiusSmall)
                            .fill(isPremium ? AJTheme.sage.opacity(0.06) : AJTheme.gold.opacity(0.06))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .ajCard()
        .padding(.horizontal)
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
    var onUpgrade: (() -> Void)? = nil

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

            if !isPremium, let onUpgrade {
                Button {
                    onUpgrade()
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text("Unlock 3 Days Per Day")
                    }
                }
                .buttonStyle(AJPremiumButtonStyle())
                .padding(.top, 4)
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
            return ("person.2.fill", AJTheme.success, "Invite an Accountability Partner", "Check the Discover tab to invite a friend to walk alongside you on this journey.")
        case 15...21:
            return ("heart.circle.fill", AJTheme.sandstone, "Try a Couples Journey", "Walk through 40 days with your partner — find it on the Discover tab under Journey.")
        case 22...30:
            return ("wand.and.stars", AJTheme.gold, "Create a Custom Journey", "Describe what you're going through and we'll build a journey just for you. Find it on the Discover tab.")
        case 31...40:
            return ("gift.fill", AJTheme.gold, "Gift a Journey", "Know someone who could use encouragement? Send them a journey from the Discover tab.")
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

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [(id: Int, x: CGFloat, delay: Double, color: Color, size: CGFloat)] = []

    private let colors: [Color] = [AJTheme.gold, AJTheme.sage, AJTheme.sageLight, AJTheme.sandstone, .yellow, .orange]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles, id: \.id) { p in
                    Circle()
                        .fill(p.color)
                        .frame(width: p.size, height: p.size)
                        .modifier(FallingParticle(x: p.x, screenHeight: geo.size.height, delay: p.delay))
                }
            }
            .onAppear {
                particles = (0..<40).map { i in
                    (id: i,
                     x: CGFloat.random(in: 0...geo.size.width),
                     delay: Double.random(in: 0...0.6),
                     color: colors.randomElement() ?? AJTheme.gold,
                     size: CGFloat.random(in: 4...10))
                }
            }
        }
    }
}

struct FallingParticle: ViewModifier, Animatable {
    let x: CGFloat
    let screenHeight: CGFloat
    let delay: Double
    @State private var y: CGFloat = -20
    @State private var opacity: Double = 1

    func body(content: Content) -> some View {
        content
            .position(x: x, y: y)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 2.0).delay(delay)) {
                    y = screenHeight + 20
                    opacity = 0
                }
            }
    }
}

// MARK: - Bookmarked Days View

struct BookmarkedDaysView: View {
    @Query private var journeys: [Journey]

    private var bookmarkedDays: [JourneyDay] {
        journeys.flatMap { $0.days ?? [] }
            .filter { $0.isBookmarked }
            .sorted { $0.dayNumber < $1.dayNumber }
    }

    var body: some View {
        Group {
            if bookmarkedDays.isEmpty {
                ContentUnavailableView(
                    "No Bookmarks Yet",
                    systemImage: "bookmark",
                    description: Text("Tap the bookmark icon on any day's devotional to save it here.")
                )
            } else {
                List(bookmarkedDays, id: \.id) { day in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: day.focusArea.icon)
                                .foregroundStyle(AJTheme.sage)
                            Text("Day \(day.dayNumber)")
                                .font(AJTheme.subheadlineFont)
                            Spacer()
                            Image(systemName: "bookmark.fill")
                                .foregroundStyle(AJTheme.gold)
                                .font(.caption)
                        }

                        Text(day.devotionalTitle)
                            .font(.system(.body, design: .serif, weight: .semibold))

                        Text("\u{201C}\(day.scriptureText.prefix(100))...\u{201D}")
                            .font(AJTheme.scriptureFont)
                            .foregroundStyle(AJTheme.secondaryText)
                            .lineLimit(2)

                        Text("— \(day.scriptureReference)")
                            .font(.caption)
                            .foregroundStyle(AJTheme.sage)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Bookmarked Days")
    }
}

// MARK: - Progress Strip

struct ProgressStripView: View {
    let journey: Journey
    let dayNumber: Int

    var body: some View {
        let streak = StreakService.shared.calculateStreak(for: journey)
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Text("\(streak.currentStreak)-day streak")
                    .font(.caption.bold())
                    .foregroundStyle(AJTheme.primaryText)
            }

            Capsule()
                .fill(AJTheme.secondaryText.opacity(0.3))
                .frame(width: 1, height: 12)

            Text("Day \(dayNumber)/\(journey.totalDays)")
                .font(.caption)
                .foregroundStyle(AJTheme.secondaryText)

            Spacer()

            Text("\(Int(journey.progress * 100))%")
                .font(.caption.bold())
                .foregroundStyle(AJTheme.sage)
        }
        .padding(.horizontal, AJTheme.paddingMedium)
        .padding(.vertical, AJTheme.paddingSmall)
        .background(
            RoundedRectangle(cornerRadius: AJTheme.cornerRadiusSmall)
                .fill(AJTheme.sage.opacity(0.06))
        )
    }
}

// MARK: - Post-Completion Suggestions

struct PostCompletionSuggestionsCard: View {
    private let suggestions: [(icon: String, color: Color, title: String, destination: AnyView)] = [
        ("brain.head.profile", .purple, "Memorize today's verse", AnyView(ScriptureMemoryView())),
        ("camera.viewfinder", .orange, "Capture a God Moment", AnyView(GodMomentsView())),
        ("wind", .teal, "Breathe & reflect", AnyView(BreathingMeditationView())),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(AJTheme.gold)
                Text("Keep Going")
                    .font(AJTheme.subheadlineFont)
                    .foregroundStyle(AJTheme.primaryText)
            }

            ForEach(Array(suggestions.enumerated()), id: \.offset) { _, suggestion in
                NavigationLink {
                    suggestion.destination
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(suggestion.color.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: suggestion.icon)
                                .font(.caption)
                                .foregroundStyle(suggestion.color)
                        }
                        Text(suggestion.title)
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(AJTheme.primaryText)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .ajCard()
    }
}

#Preview {
    DailyExperienceView()
        .modelContainer(for: Journey.self, inMemory: true)
}
