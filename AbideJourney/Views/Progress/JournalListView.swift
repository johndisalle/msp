import SwiftUI
import SwiftData

struct JournalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query private var profiles: [UserProfile]
    @State private var showingPremiumSheet = false
    @State private var showingShareSheet = false
    @State private var showingNewEntrySheet = false
    @State private var exportedPDFURL: URL?
    @State private var isExporting = false
    @State private var exportError: String?

    private var isPremium: Bool { profiles.first?.isPremium ?? false }

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
                    List {
                        // Premium users: remind them about voice journaling
                        if isPremium && !entries.contains(where: \.isVoiceEntry) {
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
                        if !isPremium && entries.count >= 5 {
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

                        Section {
                            ForEach(entries) { entry in
                                JournalEntryRow(entry: entry)
                            }
                        }
                    }
                    .listStyle(.plain)
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
                    // Mood selector
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
                                .accessibilityLabel(mood.label)
                                .accessibilityAddTraits(selectedMood == mood ? .isSelected : [])
                            }
                        }
                    }

                    // Journal text with voice toggle
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
                            .accessibilityLabel(speechService.isRecording ? "Stop recording" : "Start voice entry")
                        }

                        if speechService.isRecording {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(AJTheme.destructive)
                                    .frame(width: 8, height: 8)
                                Text("Speak your reflection — it will appear as text below")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button {
                                    speechService.stopRecording()
                                } label: {
                                    Text("Stop")
                                        .font(.caption.bold())
                                        .foregroundStyle(AJTheme.destructive)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AJTheme.destructive.opacity(0.06))
                            )
                        }

                        TextEditor(text: $journalText)
                            .frame(minHeight: 200)
                            .padding(8)
                            .background(AJTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .focused($isFocused)

                        if let error = speechService.error {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(AJTheme.destructive)
                        }
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

#Preview {
    JournalListView()
        .modelContainer(for: JournalEntry.self, inMemory: true)
}
