import SwiftUI
import SwiftData

/// AI-powered spiritual director chat that uses journey context
/// (journal entries, moods, check-ins, progress) to provide personalized guidance.
struct SpiritualDirectorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Journey> { $0.isActive }) private var journeys: [Journey]
    @Query private var profiles: [UserProfile]
    @Query private var prayerSessions: [PrayerSession]

    @State private var service = SpiritualDirectorService.shared
    @State private var inputText = ""
    @State private var hasStarted = false
    @FocusState private var isInputFocused: Bool

    private var profile: UserProfile? { profiles.first }
    private var isPremium: Bool { profile?.isPremium ?? false }

    var body: some View {
        NavigationStack {
            if !isPremium {
                premiumGate
            } else {
                chatView
            }
        }
    }

    // MARK: - Premium Gate

    private var premiumGate: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 56))
                .foregroundStyle(.accent)

            Text("AI Spiritual Director")
                .font(.title2.bold())

            Text("Get personalized spiritual guidance based on your journal entries, moods, and journey progress. Like having a wise mentor in your pocket.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 32)

            NavigationLink {
                PremiumPaywallView()
            } label: {
                Text("Unlock with Premium")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .navigationTitle("Spiritual Director")
    }

    // MARK: - Chat View

    private var chatView: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(service.messages.filter { $0.role != .system }) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }

                        if service.isLoading {
                            HStack {
                                ProgressView()
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                Spacer()
                            }
                            .padding(.horizontal)
                            .id("loading")
                        }
                    }
                    .padding(.vertical)
                }
                .onChange(of: service.messages.count) { _, _ in
                    withAnimation {
                        if service.isLoading {
                            proxy.scrollTo("loading", anchor: .bottom)
                        } else if let last = service.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input bar
            HStack(spacing: 12) {
                TextField("Ask anything...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .accent)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || service.isLoading)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
        .navigationTitle("Spiritual Director")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    hasStarted = false
                    service.clearConversation()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
            }
        }
        .onAppear {
            if !hasStarted {
                service.startConversation(context: buildContext())
                hasStarted = true
            }
        }
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""

        Task {
            await service.sendMessage(text, context: buildContext())
        }
    }

    // MARK: - Context

    private func buildContext() -> SpiritualDirectorService.JourneyContext {
        let journey = journeys.first
        let sortedDays = journey?.days.sorted { $0.dayNumber < $1.dayNumber } ?? []
        let completedDays = sortedDays.filter(\.isCompleted)
        let recentDays = completedDays.suffix(7)

        let currentDay = sortedDays.first { !$0.isCompleted && $0.isUnlocked } ?? sortedDays.last

        let recentMoods = recentDays.flatMap(\.journalEntries).compactMap { $0.mood?.label }
        let recentRatings = recentDays.flatMap(\.checkIns).map(\.rating.label)
        let recentJournals = recentDays.flatMap(\.journalEntries).suffix(3).map { String($0.text.prefix(200)) }

        let streakInfo = journey.map { StreakService.shared.calculateStreak(for: $0) }
        let totalPrayer = prayerSessions.reduce(0) { $0 + Int($1.duration / 60) }

        return SpiritualDirectorService.JourneyContext(
            userName: profile?.name ?? "Friend",
            currentDay: journey?.currentDay ?? 0,
            totalDays: journey?.totalDays ?? 40,
            journeyTheme: journey?.theme.rawValue ?? "Spiritual Growth",
            focusArea: currentDay?.focusArea.rawValue ?? "Prayer",
            recentMoods: recentMoods,
            recentCheckInRatings: recentRatings,
            recentJournalExcerpts: recentJournals,
            totalPrayerMinutes: totalPrayer,
            streakDays: streakInfo?.currentStreak ?? 0,
            scripturesToday: currentDay?.scriptureReference ?? ""
        )
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: SpiritualDirectorService.Message

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .lineSpacing(3)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isUser ? Color.accentColor : Color(.systemGray6))
            .foregroundStyle(isUser ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            if !isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal)
    }
}

#Preview {
    SpiritualDirectorView()
        .modelContainer(for: [Journey.self, UserProfile.self, PrayerSession.self], inMemory: true)
}
