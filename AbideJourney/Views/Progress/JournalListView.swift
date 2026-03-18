import SwiftUI
import SwiftData

struct JournalListView: View {
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query private var profiles: [UserProfile]
    @State private var showingPremiumSheet = false

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
            .sheet(isPresented: $showingPremiumSheet) {
                PremiumPaywallView()
            }
        }
    }
}

struct JournalEntryRow: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let mood = entry.mood {
                    Text(mood.rawValue)
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
