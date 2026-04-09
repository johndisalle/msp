import SwiftUI
import SwiftData

struct JournalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query private var profiles: [UserProfile]
    @State private var showingPremiumSheet = false
    @State private var showingShareSheet = false
    @State private var showingNewEntrySheet = false
    @State private var showingGrowthSheet = false
    @State private var editingEntry: JournalEntry?
    @State private var exportedPDFURL: URL?
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var searchText = ""
    @Query(filter: #Predicate<Journey> { $0.isActive }) private var activeJourneys: [Journey]
    @Query private var allJourneys: [Journey]

    private var isPremium: Bool { profiles.first?.isPremium ?? false }

    private var filteredEntries: [JournalEntry] {
        guard !searchText.isEmpty else { return entries }
        let query = searchText.lowercased()
        return entries.filter { entry in
            entry.text.lowercased().contains(query) ||
            entry.mood?.label.lowercased().contains(query) == true ||
            entry.journeyDay?.scriptureReference.lowercased().contains(query) == true ||
            entry.journeyDay?.reflectionPrompt.lowercased().contains(query) == true
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No Journal Entries",
                        systemImage: "book.closed",
                        description: Text("Tap + to write your first reflection, or complete a daily devotional to journal about it.")
                    )
                } else {
                    VStack(spacing: 0) {
                        // Growth snapshot
                        Button {
                            showingGrowthSheet = true
                        } label: {
                            GrowthSnapshotCard(journeys: allJourneys, entryCount: entries.count)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                        // Existing list content
                        List {
                            // Premium users: remind them about voice journaling
                            if isPremium && !entries.contains(where: \.isVoiceEntry) && searchText.isEmpty {
                                Section {
                                    HStack(spacing: 12) {
                                        Image(systemName: "mic.fill")
                                            .font(.title3)
                                            .foregroundStyle(.purple)
                                            .frame(width: 32)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Try Voice Journaling")
                                                .font(.subheadline.bold())
                                            Text("Tap the mic button when writing a reflection to speak instead of type.")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    .listRowBackground(Color.purple.opacity(0.05))
                                }
                            }

                            // Free users: export nudge after 5+ entries
                            if !isPremium && entries.count >= 5 && searchText.isEmpty {
                                Section {
                                    Button {
                                        showingPremiumSheet = true
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: "doc.richtext")
                                                .font(.title3)
                                                .foregroundStyle(.accent)
                                                .frame(width: 32)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Save your \(entries.count) reflections")
                                                    .font(.subheadline.bold())
                                                    .foregroundStyle(.primary)
                                                Text("Export your journal as a beautiful PDF with Premium")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .listRowBackground(Color.accentColor.opacity(0.05))
                                }
                            }

                            if !searchText.isEmpty && filteredEntries.isEmpty {
                                ContentUnavailableView.search(text: searchText)
                            } else {
                                Section {
                                    ForEach(filteredEntries) { entry in
                                        JournalEntryRow(entry: entry)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                editingEntry = entry
                                            }
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button(role: .destructive) {
                                                    deleteEntry(entry)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                            .swipeActions(edge: .leading) {
                                                Button {
                                                    editingEntry = entry
                                                } label: {
                                                    Label("Edit", systemImage: "pencil")
                                                }
                                                .tint(AJTheme.sage)
                                            }
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .searchable(text: $searchText, prompt: "Search reflections...")
                    }
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        if isPremium && !entries.isEmpty {
                            Button {
                                exportPDF()
                            } label: {
                                if isExporting {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Label("Export PDF", systemImage: "square.and.arrow.up")
                                }
                            }
                            .disabled(isExporting)
                        }

                        Button {
                            showingNewEntrySheet = true
                        } label: {
                            Label("New Entry", systemImage: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingPremiumSheet) {
                PremiumPaywallView()
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedPDFURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showingNewEntrySheet) {
                StandaloneJournalSheet(modelContext: modelContext)
            }
            .sheet(item: $editingEntry) { entry in
                EditJournalSheet(entry: entry, modelContext: modelContext)
            }
            .sheet(isPresented: $showingGrowthSheet) {
                MyGrowthSheet()
            }
            .alert("Export Failed", isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button("OK") { exportError = nil }
            } message: {
                Text(exportError ?? "")
            }
        }
    }

    private func deleteEntry(_ entry: JournalEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }

    private func exportPDF() {
        isExporting = true
        let userName = profiles.first?.name ?? "Journal"
        let entriesSnapshot = Array(entries)

        DispatchQueue.global(qos: .userInitiated).async {
            let pdfData = PDFExportService.shared.generateJournalPDF(
                entries: entriesSnapshot,
                userName: userName
            )

            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("AbideJourney-Journal.pdf")
            do {
                try pdfData.write(to: tempURL)
            } catch {
                DispatchQueue.main.async {
                    exportError = "Could not save the PDF for sharing. Please try again."
                    isExporting = false
                }
                return
            }

            DispatchQueue.main.async {
                exportedPDFURL = tempURL
                isExporting = false
                showingShareSheet = true
            }
        }
    }
}

// MARK: - Edit Journal Sheet

struct EditJournalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: JournalEntry
    let modelContext: ModelContext
    @State private var editText: String = ""
    @State private var editMood: Mood?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let day = entry.journeyDay, !day.reflectionPrompt.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reflection Prompt")
                                .font(AJTheme.captionFont)
                                .foregroundStyle(AJTheme.secondaryText)
                            Text(day.reflectionPrompt)
                                .font(AJTheme.scriptureFont)
                                .italic()
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AJTheme.cream.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("How are you feeling?")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)

                        HStack(spacing: 12) {
                            ForEach(Mood.allCases, id: \.self) { mood in
                                Button {
                                    editMood = mood
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: mood.sfSymbol)
                                            .font(.title2)
                                            .foregroundStyle(mood.color)
                                        Text(mood.label)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(editMood == mood ? AJTheme.sage.opacity(0.15) : .clear)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Reflection")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $editText)
                            .frame(minHeight: 200)
                            .padding(8)
                            .background(AJTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        entry.text = editText
                        entry.mood = editMood
                        entry.updatedAt = Date()
                        try? modelContext.save()
                        dismiss()
                    }
                    .bold()
                    .disabled(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                editText = entry.text
                editMood = entry.mood
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Standalone Journal Entry Sheet

struct StandaloneJournalSheet: View {
    @Environment(\.dismiss) private var dismiss
    let modelContext: ModelContext
    @State private var journalText = ""
    @State private var selectedMood: Mood?
    @State private var isVoiceEntry = false
    @FocusState private var isFocused: Bool
    @State private var speechService = SpeechRecognitionService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How are you feeling?")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)

                        HStack(spacing: 12) {
                            ForEach(Mood.allCases, id: \.self) { mood in
                                Button {
                                    selectedMood = mood
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: mood.sfSymbol)
                                            .font(.title2)
                                            .foregroundStyle(mood.color)
                                        Text(mood.label)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedMood == mood ? AJTheme.sage.opacity(0.15) : .clear)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("What's on your heart?")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                toggleVoiceMode()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: speechService.isRecording ? "mic.fill" : "mic")
                                        .font(.caption)
                                    Text(speechService.isRecording ? "Listening..." : "Voice")
                                        .font(.caption)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(speechService.isRecording ? AJTheme.destructive.opacity(0.15) : AJTheme.sage.opacity(0.1))
                                )
                                .foregroundStyle(speechService.isRecording ? AJTheme.destructive : AJTheme.sage)
                            }
                        }

                        TextEditor(text: $journalText)
                            .frame(minHeight: 200)
                            .padding(8)
                            .background(AJTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .focused($isFocused)
                    }
                }
                .padding()
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        speechService.stopRecording()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        speechService.stopRecording()
                        saveEntry()
                        dismiss()
                    }
                    .bold()
                    .disabled(journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { isFocused = true }
            .onDisappear { speechService.stopRecording() }
            .onChange(of: speechService.transcribedText) { _, newText in
                if speechService.isRecording, !newText.isEmpty {
                    journalText = newText
                }
            }
        }
        .presentationDetents([.large])
    }

    private func saveEntry() {
        let trimmed = journalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let entry = JournalEntry(text: trimmed, mood: selectedMood, isVoiceEntry: isVoiceEntry)
        modelContext.insert(entry)
        try? modelContext.save()
    }

    private func toggleVoiceMode() {
        if speechService.isRecording {
            speechService.stopRecording()
        } else {
            isFocused = false
            Task {
                await speechService.requestAuthorization()
                if speechService.isAuthorized {
                    if !journalText.isEmpty {
                        speechService.transcribedText = journalText
                    }
                    await MainActor.run {
                        speechService.startRecording()
                    }
                    isVoiceEntry = true
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct JournalEntryRow: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let mood = entry.mood {
                    Image(systemName: mood.sfSymbol)
                        .foregroundStyle(mood.color)
                }
                if entry.isVoiceEntry {
                    Image(systemName: "mic.fill")
                        .font(.caption)
                        .foregroundStyle(.purple)
                }
                if let day = entry.journeyDay {
                    Text("Day \(day.dayNumber)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(Capsule())
                } else {
                    Text("Personal")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AJTheme.sandstone.opacity(0.15))
                        .clipShape(Capsule())
                }
                Spacer()
                Text(entry.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let day = entry.journeyDay, !day.reflectionPrompt.isEmpty {
                Text(day.reflectionPrompt)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Text(entry.text)
                .font(.body)
                .lineLimit(3)

            if let day = entry.journeyDay {
                Text(day.scriptureReference)
                    .font(.caption)
                    .foregroundStyle(.accent)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Growth Snapshot Card

struct GrowthSnapshotCard: View {
    let journeys: [Journey]
    let entryCount: Int

    private var activeJourney: Journey? {
        journeys.first(where: { $0.isActive && !$0.isCompleted })
    }

    private var streakCount: Int {
        guard let journey = activeJourney else { return 0 }
        return StreakService.shared.calculateStreak(for: journey).currentStreak
    }

    private var badgeCount: Int {
        AchievementService.shared.earnedBadgeIDs.count
    }

    var body: some View {
        HStack(spacing: 0) {
            // Streak
            statItem(
                icon: "flame.fill",
                color: .orange,
                value: "\(streakCount)",
                label: "streak"
            )

            Capsule()
                .fill(AJTheme.secondaryText.opacity(0.2))
                .frame(width: 1, height: 28)

            // Badges
            statItem(
                icon: "trophy.fill",
                color: .yellow,
                value: "\(badgeCount)",
                label: "badges"
            )

            Capsule()
                .fill(AJTheme.secondaryText.opacity(0.2))
                .frame(width: 1, height: 28)

            // Journey progress
            if let journey = activeJourney {
                statItem(
                    icon: "book.fill",
                    color: AJTheme.sage,
                    value: "Day \(journey.currentDay)",
                    label: "of \(journey.totalDays)"
                )
            } else {
                statItem(
                    icon: "book.fill",
                    color: AJTheme.sage,
                    value: "\(entryCount)",
                    label: "entries"
                )
            }

            Spacer()

            // "My Growth" chevron
            HStack(spacing: 4) {
                Text("My Growth")
                    .font(.caption.bold())
                    .foregroundStyle(AJTheme.sage)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(AJTheme.sage)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AJTheme.cornerRadius)
                .fill(AJTheme.cardBackground)
                .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
        )
    }

    private func statItem(icon: String, color: Color, value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.caption.bold())
                    .foregroundStyle(AJTheme.primaryText)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(AJTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - My Growth Sheet

struct MyGrowthSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var journeys: [Journey]
    @Query private var journalEntries: [JournalEntry]
    @Query private var profiles: [UserProfile]
    @State private var viewModel = ProgressViewModel()
    @State private var showingPremiumSheet = false

    private var isPremium: Bool { profiles.first?.isPremium ?? false }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AJTheme.paddingLarge) {
                    // Journey progress
                    if let journey = viewModel.journey {
                        JourneyProgressCard(journey: journey)
                    }

                    // Streak
                    if let streak = viewModel.streakInfo {
                        StreakCard(streakInfo: streak)
                    }

                    // Achievements
                    NavigationLink {
                        AchievementsView()
                    } label: {
                        AchievementsSummaryCard(journeys: journeys, journalCount: journalEntries.count)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    // Faith Wrapped
                    NavigationLink {
                        FaithWrappedView()
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 0.15, green: 0.20, blue: 0.38), Color(red: 0.30, green: 0.15, blue: 0.45)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                Image(systemName: "sparkles")
                                    .font(.body)
                                    .foregroundStyle(.white)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(verbatim: "\(Calendar.current.component(.year, from: Date())) Faith Wrapped")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AJTheme.primaryText)
                                Text("Your year in review — shareable!")
                                    .font(.caption)
                                    .foregroundStyle(AJTheme.secondaryText)
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
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    // Habit rings
                    HabitRingsCard(
                        prayer: viewModel.prayerRingProgress,
                        word: viewModel.wordRingProgress,
                        obedience: viewModel.obedienceRingProgress,
                        worship: viewModel.worshipRingProgress
                    )

                    // Weekly stats
                    WeeklyStatsCard(
                        prayerDays: viewModel.weeklyPrayerCount,
                        scriptureCount: viewModel.weeklyScriptureCount,
                        obedienceCount: viewModel.weeklyObedienceCount
                    )

                    // Calendar
                    if let journey = viewModel.journey {
                        StreakCalendarView(journey: journey)
                    }

                    // Premium features (visible to all)
                    NavigationLink {
                        FaithMapView()
                    } label: {
                        PremiumProgressCard(
                            icon: "map.fill",
                            color: .teal,
                            title: "Faith Map",
                            subtitle: "See your spiritual growth visualized over time"
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    if isPremium {
                        NavigationLink {
                            FaithReportView()
                        } label: {
                            PremiumProgressCard(
                                icon: "sparkles.rectangle.stack.fill",
                                color: .indigo,
                                title: "Annual Faith Report",
                                subtitle: "A beautiful summary of your year with God"
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)

                        NavigationLink {
                            AccountabilityView()
                        } label: {
                            PremiumProgressCard(
                                icon: "person.2.fill",
                                color: .green,
                                title: "Accountability Partners",
                                subtitle: "Invite a friend to walk alongside you"
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    } else {
                        // Show premium features as locked previews
                        lockedFeatureCard(
                            icon: "sparkles.rectangle.stack.fill",
                            color: .indigo,
                            title: "Annual Faith Report",
                            subtitle: "A beautiful summary of your year with God"
                        )

                        lockedFeatureCard(
                            icon: "person.2.fill",
                            color: .green,
                            title: "Accountability Partners",
                            subtitle: "Invite a friend to walk alongside you"
                        )
                    }
                }
                .padding(.vertical)
            }
            .ajScreenBackground()
            .navigationTitle("My Growth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .bold()
                }
            }
            .onAppear {
                viewModel.loadProgress(from: journeys)
            }
            .sheet(isPresented: $showingPremiumSheet) {
                PremiumPaywallView()
            }
        }
    }

    private func lockedFeatureCard(icon: String, color: Color, title: String, subtitle: String) -> some View {
        Button {
            showingPremiumSheet = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(AJTheme.primaryText)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AJTheme.secondaryText)
                }
                Spacer()
                Text("Premium")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(AJTheme.gold))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AJTheme.cardBackground)
                    .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

#Preview {
    JournalListView()
        .modelContainer(for: JournalEntry.self, inMemory: true)
}
