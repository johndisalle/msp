import SwiftUI
import SwiftData

struct DailyExperienceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Journey> { $0.isActive }) private var journeys: [Journey]
    @State private var viewModel = DailyExperienceViewModel()

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
                                text: day.devotionalText
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

                            // Prayer timer button
                            Button {
                                viewModel.showingPrayerTimer = true
                            } label: {
                                HStack {
                                    Image(systemName: "timer")
                                    Text("Start Prayer Timer")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .padding(.horizontal)

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
                PrayerTimerView(timerService: viewModel.prayerTimer) {
                    viewModel.savePrayerSession(context: modelContext)
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
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .foregroundStyle(.orange)
                Text("Devotional")
                    .font(.headline)
                Spacer()
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

#Preview {
    DailyExperienceView()
        .modelContainer(for: Journey.self, inMemory: true)
}
