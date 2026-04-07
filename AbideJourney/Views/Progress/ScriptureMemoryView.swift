import SwiftUI
import SwiftData

// MARK: - Scripture Memory Data

/// Stored in UserDefaults as JSON for simplicity (no SwiftData migration needed).
struct MemoryVerse: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var reference: String
    var text: String
    var addedAt: Date = Date()
    var lastReviewedAt: Date?
    var reviewCount: Int = 0
    var masteryLevel: MasteryLevel = .new

    enum MasteryLevel: String, Codable, CaseIterable {
        case new = "New"
        case learning = "Learning"
        case familiar = "Familiar"
        case memorized = "Memorized"

        var color: Color {
            switch self {
            case .new: return .secondary
            case .learning: return .orange
            case .familiar: return .blue
            case .memorized: return .green
            }
        }

        var icon: String {
            switch self {
            case .new: return "sparkle"
            case .learning: return "brain"
            case .familiar: return "star.leadinghalf.filled"
            case .memorized: return "star.fill"
            }
        }

        var next: MasteryLevel {
            switch self {
            case .new: return .learning
            case .learning: return .familiar
            case .familiar: return .memorized
            case .memorized: return .memorized
            }
        }
    }
}

// MARK: - Memory Verse Storage

final class ScriptureMemoryService {
    static let shared = ScriptureMemoryService()
    private let key = "savedMemoryVerses"

    private init() {}

    func loadVerses() -> [MemoryVerse] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let verses = try? JSONDecoder().decode([MemoryVerse].self, from: data)
        else { return [] }
        return verses.sorted { ($0.lastReviewedAt ?? $0.addedAt) < ($1.lastReviewedAt ?? $1.addedAt) }
    }

    func save(_ verses: [MemoryVerse]) {
        if let data = try? JSONEncoder().encode(verses) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func addVerse(reference: String, text: String) {
        var verses = loadVerses()
        guard !verses.contains(where: { $0.reference == reference }) else { return }
        verses.append(MemoryVerse(reference: reference, text: text))
        save(verses)
    }

    func removeVerse(id: UUID) {
        var verses = loadVerses()
        verses.removeAll { $0.id == id }
        save(verses)
    }

    func markReviewed(id: UUID, promoted: Bool) {
        var verses = loadVerses()
        guard let index = verses.firstIndex(where: { $0.id == id }) else { return }
        verses[index].lastReviewedAt = Date()
        verses[index].reviewCount += 1
        if promoted {
            verses[index].masteryLevel = verses[index].masteryLevel.next
        }
        save(verses)
    }
}

// MARK: - Scripture Memory List View

struct ScriptureMemoryView: View {
    @State private var verses: [MemoryVerse] = []
    @State private var showingFlashcards = false
    @State private var selectedVerse: MemoryVerse?

    private let service = ScriptureMemoryService.shared

    private var dueForReview: [MemoryVerse] {
        verses.filter { verse in
            guard verse.masteryLevel != .memorized else { return false }
            guard let last = verse.lastReviewedAt else { return true }
            let hours: Double
            switch verse.masteryLevel {
            case .new: hours = 4
            case .learning: hours = 24
            case .familiar: hours = 72
            case .memorized: hours = 168
            }
            return Date().timeIntervalSince(last) > hours * 3600
        }
    }

    var body: some View {
        Group {
            if verses.isEmpty {
                ContentUnavailableView(
                    "No Verses Saved",
                    systemImage: "brain.head.profile",
                    description: Text("Tap \"Memorize\" on any scripture card in your daily devotional to start building your memory deck.")
                )
            } else {
                List {
                    // Review prompt
                    if !dueForReview.isEmpty {
                        Section {
                            Button {
                                showingFlashcards = true
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(AJTheme.sage.opacity(0.15))
                                            .frame(width: 48, height: 48)
                                        Image(systemName: "rectangle.stack.fill")
                                            .font(.title3)
                                            .foregroundStyle(AJTheme.sage)
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Review \(dueForReview.count) verse\(dueForReview.count == 1 ? "" : "s")")
                                            .font(.headline)
                                            .foregroundStyle(AJTheme.primaryText)
                                        Text("Flashcard practice — tap to start")
                                            .font(.caption)
                                            .foregroundStyle(AJTheme.secondaryText)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(AJTheme.sage.opacity(0.05))
                        }
                    }

                    // Stats
                    Section {
                        HStack(spacing: 0) {
                            MasteryStatView(count: verses.filter { $0.masteryLevel == .new }.count, level: .new)
                            MasteryStatView(count: verses.filter { $0.masteryLevel == .learning }.count, level: .learning)
                            MasteryStatView(count: verses.filter { $0.masteryLevel == .familiar }.count, level: .familiar)
                            MasteryStatView(count: verses.filter { $0.masteryLevel == .memorized }.count, level: .memorized)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }

                    // Verse list
                    Section("Your Verses") {
                        ForEach(verses) { verse in
                            VerseRow(verse: verse)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        service.removeVerse(id: verse.id)
                                        verses = service.loadVerses()
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Scripture Memory")
        .onAppear { verses = service.loadVerses() }
        .fullScreenCover(isPresented: $showingFlashcards, onDismiss: {
            verses = service.loadVerses()
        }) {
            FlashcardReviewView(verses: dueForReview)
        }
    }
}

// MARK: - Verse Row

private struct VerseRow: View {
    let verse: MemoryVerse

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(verse.reference)
                    .font(.subheadline.bold())
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: verse.masteryLevel.icon)
                        .font(.caption2)
                    Text(verse.masteryLevel.rawValue)
                        .font(.caption2.bold())
                }
                .foregroundStyle(verse.masteryLevel.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(verse.masteryLevel.color.opacity(0.12))
                .clipShape(Capsule())
            }

            Text(verse.text)
                .font(.caption)
                .foregroundStyle(AJTheme.secondaryText)
                .lineLimit(2)

            HStack {
                Text("Reviewed \(verse.reviewCount)x")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                if let last = verse.lastReviewedAt {
                    Text("Last: \(last, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Mastery Stat

private struct MasteryStatView: View {
    let count: Int
    let level: MemoryVerse.MasteryLevel

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title3.bold())
                .foregroundStyle(level.color)
            Text(level.rawValue)
                .font(.caption2)
                .foregroundStyle(AJTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

// MARK: - Flashcard Review

struct FlashcardReviewView: View {
    @Environment(\.dismiss) private var dismiss
    let verses: [MemoryVerse]
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var progress: CGFloat = 0
    @State private var showingCompletion = false

    private let service = ScriptureMemoryService.shared

    private var currentVerse: MemoryVerse? {
        guard currentIndex < verses.count else { return nil }
        return verses[currentIndex]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: progress)
                    .tint(AJTheme.sage)
                    .padding(.horizontal)
                    .padding(.top, 8)

                Text("\(currentIndex + 1) of \(verses.count)")
                    .font(.caption)
                    .foregroundStyle(AJTheme.secondaryText)
                    .padding(.top, 4)

                Spacer()

                if showingCompletion {
                    completionView
                } else if let verse = currentVerse {
                    // Flashcard
                    flashcard(for: verse)

                    Spacer()

                    // Action buttons
                    if isFlipped {
                        HStack(spacing: 16) {
                            Button {
                                advanceCard(promoted: false)
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.title3)
                                    Text("Still Learning")
                                        .font(.caption.bold())
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AJTheme.sandstone.opacity(0.15))
                                .foregroundStyle(AJTheme.sandstone)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            Button {
                                advanceCard(promoted: true)
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                    Text("Got It!")
                                        .font(.caption.bold())
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AJTheme.sage.opacity(0.15))
                                .foregroundStyle(AJTheme.sage)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    } else {
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                isFlipped = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "eye.fill")
                                Text("Show Verse")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AJTheme.sage)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
            .ajScreenBackground()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func flashcard(for verse: MemoryVerse) -> some View {
        VStack(spacing: 20) {
            Text(verse.reference)
                .font(.system(.title2, design: .serif, weight: .bold))
                .foregroundStyle(AJTheme.sage)

            if isFlipped {
                Text("\u{201C}\(verse.text)\u{201D}")
                    .font(AJTheme.scriptureFont)
                    .foregroundStyle(AJTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(AJTheme.secondaryText.opacity(0.4))
                    Text("Can you recall this verse?")
                        .font(.subheadline)
                        .foregroundStyle(AJTheme.secondaryText)
                }
                .padding(.vertical, 20)
            }

            HStack(spacing: 4) {
                Image(systemName: verse.masteryLevel.icon)
                    .font(.caption2)
                Text(verse.masteryLevel.rawValue)
                    .font(.caption2)
            }
            .foregroundStyle(verse.masteryLevel.color)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AJTheme.cardBackground)
                .shadow(color: AJTheme.cardShadow, radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 24)
    }

    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(AJTheme.sage)

            Text("Review Complete!")
                .font(AJTheme.titleFont)

            Text("You reviewed \(verses.count) verse\(verses.count == 1 ? "" : "s"). Keep it up!")
                .font(.subheadline)
                .foregroundStyle(AJTheme.secondaryText)
                .multilineTextAlignment(.center)

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AJTheme.sage)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)
            .padding(.top, 12)
        }
    }

    private func advanceCard(promoted: Bool) {
        if let verse = currentVerse {
            service.markReviewed(id: verse.id, promoted: promoted)
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        if currentIndex + 1 >= verses.count {
            withAnimation {
                progress = 1
                showingCompletion = true
            }
        } else {
            withAnimation {
                currentIndex += 1
                isFlipped = false
                progress = CGFloat(currentIndex) / CGFloat(verses.count)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ScriptureMemoryView()
    }
}
