import Foundation

/// Persists in-progress journal drafts so text isn't lost if the user
/// closes the sheet (or the app) before calling `completeDay`.
///
/// FIX H24: The JournalEntrySheet's "Save" button only propagates text up
/// to the view model — the permanent SwiftData `JournalEntry` is created
/// in `completeDay`. Between "Save & close sheet" and "Complete Day," the
/// text lives only in view-model memory and is lost if the session ends.
///
/// This store keeps per-day drafts in UserDefaults (tiny, no migration
/// concerns) keyed by the JourneyDay's UUID. `DailyExperienceViewModel`
/// clears the draft in `completeDay` once the real JournalEntry is saved.
///
/// Mood and voice-entry state are tracked alongside the text so the user
/// returns to the exact sheet state they left.
final class JournalDraftStore {
    static let shared = JournalDraftStore()

    private struct Draft: Codable {
        var text: String
        var moodRaw: String?
        var isVoiceEntry: Bool
        var updatedAt: Date
    }

    private let defaults = UserDefaults.standard
    private let prefix = "journal_draft_"
    // Drafts older than 14 days are garbage-collected on access so a
    // stale draft from a deleted journey day can't haunt the user.
    private let maxAge: TimeInterval = 14 * 24 * 60 * 60

    private init() {}

    // MARK: - Public API

    func saveDraft(for dayID: UUID, text: String, mood: String?, isVoiceEntry: Bool) {
        // Don't write an empty draft — treat empty + no mood as "no draft".
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty && mood == nil {
            clearDraft(for: dayID)
            return
        }

        let draft = Draft(text: text, moodRaw: mood, isVoiceEntry: isVoiceEntry, updatedAt: Date())
        guard let data = try? JSONEncoder().encode(draft) else { return }
        defaults.set(data, forKey: key(for: dayID))
    }

    func loadDraft(for dayID: UUID) -> (text: String, mood: String?, isVoiceEntry: Bool)? {
        guard let data = defaults.data(forKey: key(for: dayID)),
              let draft = try? JSONDecoder().decode(Draft.self, from: data)
        else { return nil }

        // Auto-expire old drafts.
        if Date().timeIntervalSince(draft.updatedAt) > maxAge {
            clearDraft(for: dayID)
            return nil
        }

        return (draft.text, draft.moodRaw, draft.isVoiceEntry)
    }

    func clearDraft(for dayID: UUID) {
        defaults.removeObject(forKey: key(for: dayID))
    }

    // MARK: - Private

    private func key(for dayID: UUID) -> String {
        prefix + dayID.uuidString
    }
}
