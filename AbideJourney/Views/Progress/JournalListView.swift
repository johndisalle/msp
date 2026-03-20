import SwiftUI
import SwiftData

struct JournalListView: View {
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query private var profiles: [UserProfile]
    @State private var showingPremiumSheet = false
    @State private var showingShareSheet = false
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
                        description: Text("Your reflections will appear here as you complete your daily devotionals.")
                    )
                } else {
                    List {
                        // Subtle export nudge after 5+ entries (only for free users)
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
                if isPremium && !entries.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
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
                    Text(mood.rawValue)
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
                }
                Spacer()
                Text(entry.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
