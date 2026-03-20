// SoundManager.swift
// FaithForge
//
// Lightweight sound effects using system sounds. No bundled audio files needed.
// Uses AudioServicesPlaySystemSound for minimal overhead.

import AVFoundation
import AudioToolbox

@MainActor
final class SoundManager {
    static let shared = SoundManager()

    /// Whether sound effects are enabled. Respects user preference.
    var isEnabled: Bool = true

    private init() {
        // Configure audio session to mix with other audio (music, podcasts)
        try? AVAudioSession.sharedInstance().setCategory(
            .ambient,
            mode: .default,
            options: [.mixWithOthers]
        )
    }

    // MARK: - Sound Effects

    /// Short "ding" for quest completion.
    func playQuestComplete() {
        guard isEnabled else { return }
        // System sound 1057 = subtle completion chime
        AudioServicesPlaySystemSound(1057)
    }

    /// Ascending tone for XP award.
    func playXPAwarded() {
        guard isEnabled else { return }
        // System sound 1054 = ascending notification
        AudioServicesPlaySystemSound(1054)
    }

    /// Triumphant sound for level-up.
    func playLevelUp() {
        guard isEnabled else { return }
        // System sound 1025 = new mail / achievement
        AudioServicesPlaySystemSound(1025)
    }

    /// Ring closure celebration.
    func playRingClosed() {
        guard isEnabled else { return }
        // System sound 1026 = sent mail whoosh
        AudioServicesPlaySystemSound(1026)
    }

    /// Badge unlock sound.
    func playBadgeUnlocked() {
        guard isEnabled else { return }
        // System sound 1016 = tweet sent
        AudioServicesPlaySystemSound(1016)
    }

    /// Timer tick (for the last 5 seconds of a timer quest).
    func playTimerTick() {
        guard isEnabled else { return }
        // System sound 1103 = keyboard tap
        AudioServicesPlaySystemSound(1103)
    }

    /// Timer complete bell.
    func playTimerDone() {
        guard isEnabled else { return }
        // System sound 1013 = alarm bell
        AudioServicesPlaySystemSound(1013)
    }

    /// Streak at-risk warning.
    func playStreakWarning() {
        guard isEnabled else { return }
        // System sound 1006 = failure / error tone
        AudioServicesPlaySystemSound(1006)
    }

    /// Gentle tap for UI interactions.
    func playTap() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1104)
    }
}
