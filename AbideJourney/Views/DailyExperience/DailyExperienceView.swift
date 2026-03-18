import SwiftUI
import SwiftData

struct DailyExperienceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Journey> { $0.isActive }) private var journeys: [Journey]
    @Query private var profiles: [UserProfile]
    @State private var viewModel = DailyExperienceViewModel()
    @State private var showingPremiumSheet = false
    @State private var showingCompletionSheet = false

    private var isPremium: Bool { profiles.first?.isPremium ?? false }

    var body: some View {
        NavigationStack {
            Group {
                if let day = viewModel.currentDay, let journey = viewModel.journey {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Day header
                            DayHeaderView(
                                dayNumber: day.dayNumber,
                                totalDays: journey.totalDays,
                                focusArea: day.focusArea,
                                progress: journey.progress
                            )

                            // Scripture card
                            ScriptureCardView(
                                reference: day.scriptureReference,
                                text: day.scriptureText
                            )

                            // Devotional
                            DevotionalCardView(
                                title: day.devotionalTitle,
                                text: day.devotionalText,
                                isPremium: isPremium,
                                audioURL: day.devotionalAudioURL,
                                audioPlayer: isPremium ? viewModel.audioPlayer : nil,
                                onTapListenPremium: isPremium ? nil : {
                                    showingPremiumSheet = true
                                },
                                onTapListen: isPremium ? {
                                    viewModel.toggleAudio(for: day)
                                } : nil
                            )

                            // Action steps
                            ActionStepsCardView(
                                steps: $viewModel.actionSteps,
                                onToggle: { index in
                                    viewModel.toggleActionStep(at: index)
                                }
                            )

                            // Reflection & Journal
                            ReflectionCardView(
                                prompt: day.reflectionPrompt,
                                onTapJournal: {
                                    viewModel.showingJournalSheet = true
                                }
                            )

                            // Prayer section with guidance
                            PrayerCardView(
                                focusArea: day.focusArea,
                                scriptureReference: day.scriptureReference,
                                onStartPrayer: {
                                    viewModel.showingPrayerTimer = true
                                }
                            )

                            // Complete day button
                            Button {
                                viewModel.showingCheckInSheet = true
                            } label: {
                                Text("Complete Day \(day.dayNumber)")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 32)
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No Active Journey",
                        systemImage: "book.closed",
                        description: Text("Start a new journey from Settings to begin.")
                    )
                }
            }
            .navigationTitle("Today")
            .onAppear {
                viewModel.loadCurrentDay(from: journeys)
            }
            .sheet(isPresented: $viewModel.showingJournalSheet) {
                JournalEntrySheet(
                    journalText: $viewModel.journalText,
                    selectedMood: $viewModel.selectedMood,
                    prompt: viewModel.currentDay?.reflectionPrompt ?? ""
                )
            }
            .sheet(isPresented: $viewModel.showingCheckInSheet) {
                CheckInSheet { rating, note in
                    viewModel.submitCheckIn(rating: rating, note: note, context: modelContext)
                    viewModel.completeDay(context: modelContext)
                }
            }
            .sheet(isPresented: $viewModel.showingPrayerTimer) {
                PrayerTimerView(
                    timerService: viewModel.prayerTimer,
                    onSave: { viewModel.savePrayerSession(context: modelContext) },
                    focusArea: viewModel.currentDay?.focusArea,
                    scriptureReference: viewModel.currentDay?.scriptureReference
                )
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
            .onChange(of: viewModel.journeyJustCompleted) { _, completed in
                if completed {
                    showingCompletionSheet = true
                    viewModel.journeyJustCompleted = false
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
                        .font(.largeTitle.bold())
                    HStack(spacing: 6) {
                        Image(systemName: focusArea.icon)
                        Text(focusArea.rawValue)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 6)
                        .frame(width: 60, height: 60)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    Text("\(dayNumber)/\(totalDays)")
                        .font(.caption2.bold())
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Journey progress, day \(dayNumber) of \(totalDays), \(Int(progress * 100)) percent complete")
            }

            ProgressView(value: progress)
                .tint(.accent)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
        .padding(.horizontal)
    }
}

// MARK: - Scripture Card

struct ScriptureCardView: View {
    let reference: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.book.closed.fill")
                    .foregroundStyle(.accent)
                Text("Scripture")
                    .font(.headline)
                Spacer()
            }

            Text(""\(text)"")
                .font(.body)
                .italic()
                .lineSpacing(4)

            Text("— \(reference)")
                .font(.subheadline.bold())
                .foregroundStyle(.accent)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.accentColor.opacity(0.08))
        )
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
    var audioURL: String?
    var audioPlayer: AudioPlayerService?
    var onTapListenPremium: (() -> Void)?
    var onTapListen: (() -> Void)?
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .foregroundStyle(.orange)
                Text("Devotional")
                    .font(.headline)
                Spacer()

                if isPremium, let onPlay = onTapListen {
                    // Premium user — functional listen button
                    Button {
                        onPlay()
                    } label: {
                        HStack(spacing: 4) {
                            if let player = audioPlayer, player.isLoading {
                                ProgressView()
                                    .controlSize(.mini)
                            } else {
                                Image(systemName: audioPlayer?.isPlaying == true ? "pause.fill" : "speaker.wave.2")
                                    .font(.caption)
                            }
                            Text(audioPlayer?.isPlaying == true ? "Pause" : "Listen")
                                .font(.caption)
                        }
                        .foregroundStyle(.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                    }
                    .accessibilityLabel(audioPlayer?.isPlaying == true ? "Pause devotional audio" : "Listen to devotional")
                } else if !isPremium, let onTap = onTapListenPremium {
                    // Free user — premium nudge
                    Button {
                        onTap()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "speaker.wave.2")
                                .font(.caption)
                            Text("Listen")
                                .font(.caption)
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color(.systemGray5)))
                    }
                    .accessibilityLabel("Listen to devotional, premium feature")
                }
            }

            Text(title)
                .font(.title3.bold())

            Text(text)
                .font(.body)
                .lineSpacing(4)
                .lineLimit(isExpanded ? nil : 4)

            if !isExpanded {
                Button("Read more") {
                    withAnimation { isExpanded = true }
                }
                .font(.subheadline.bold())
            }

            // Audio player controls — shown when audio is active
            if let player = audioPlayer, (player.isPlaying || player.currentTime > 0) && isPremium {
                VStack(spacing: 8) {
                    // Progress bar
                    ProgressView(value: player.progress)
                        .tint(.accent)

                    HStack {
                        Text(player.formattedCurrentTime)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()

                        Spacer()

                        // Playback controls
                        HStack(spacing: 20) {
                            Button { player.skipBackward() } label: {
                                Image(systemName: "gobackward.15")
                                    .font(.caption)
                            }

                            Button { player.togglePlayPause() } label: {
                                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.title2)
                            }

                            Button { player.skipForward() } label: {
                                Image(systemName: "goforward.15")
                                    .font(.caption)
                            }
                        }
                        .foregroundStyle(.accent)

                        Spacer()

                        Text("-\(player.formattedRemaining)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
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
                    .foregroundStyle(.green)
                Text("Action Steps")
                    .font(.headline)
                Spacer()
                Text("\(steps.filter(\.isCompleted).count)/\(steps.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                Button {
                    onToggle(index)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(step.isCompleted ? .green : .secondary)
                            .font(.title3)

                        Text(step.text)
                            .font(.body)
                            .strikethrough(step.isCompleted)
                            .foregroundStyle(step.isCompleted ? .secondary : .primary)
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
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
                    .foregroundStyle(.purple)
                Text("Reflection")
                    .font(.headline)
                Spacer()
            }

            Text(prompt)
                .font(.body)
                .italic()
                .lineSpacing(4)

            Button {
                onTapJournal()
            } label: {
                HStack {
                    Image(systemName: "square.and.pencil")
                    Text("Write in Journal")
                }
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.purple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
}

// MARK: - Prayer Card

struct PrayerCardView: View {
    let focusArea: DiscipleshipArea
    let scriptureReference: String
    let onStartPrayer: () -> Void

    @State private var showingSteps = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "hands.sparkles.fill")
                    .foregroundStyle(.yellow)
                Text("Prayer")
                    .font(.headline)
                Spacer()
                Image(systemName: "timer")
                    .foregroundStyle(.secondary)
            }

            // Encouraging message
            Text("Prayer is simply talking to God. There's no wrong way to do it — just be yourself.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)

            // Expandable prayer steps
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingSteps.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                    Text("Not sure what to say? Here's a simple guide")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: showingSteps ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if showingSteps {
                VStack(alignment: .leading, spacing: 12) {
                    PrayerStepRow(
                        number: "1",
                        title: "Thank Him",
                        description: "Start by thanking God for something specific today.",
                        color: .green
                    )
                    PrayerStepRow(
                        number: "2",
                        title: "Be Honest",
                        description: "Tell God what's on your heart — worries, joys, questions. He can handle it all.",
                        color: .blue
                    )
                    PrayerStepRow(
                        number: "3",
                        title: "Ask",
                        description: "Pray for your needs and for others. Nothing is too small.",
                        color: .purple
                    )
                    PrayerStepRow(
                        number: "4",
                        title: "Listen",
                        description: "Sit quietly for a moment. God speaks through peace, through His Word, and through the stillness.",
                        color: .orange
                    )

                    HStack(spacing: 6) {
                        Image(systemName: "text.book.closed.fill")
                            .font(.caption)
                            .foregroundStyle(.accent)
                        Text("Try praying today's scripture back to God: \(scriptureReference)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
                .padding(.leading, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Start prayer button
            Button {
                onStartPrayer()
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.caption)
                    Text("Start Prayer Timer")
                }
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
}

#Preview {
    DailyExperienceView()
        .modelContainer(for: Journey.self, inMemory: true)
}
