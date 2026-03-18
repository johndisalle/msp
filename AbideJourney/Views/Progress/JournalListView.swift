import SwiftUI
import SwiftData

struct JournalListView: View {
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

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
                        ForEach(entries) { entry in
                            JournalEntryRow(entry: entry)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Journal")
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
