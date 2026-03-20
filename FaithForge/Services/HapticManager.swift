// HapticManager.swift
// FaithForge
//
// Centralized haptic feedback for quest completion, level-ups, ring closures, and UI interactions.

import UIKit
import CoreHaptics

@MainActor
final class HapticManager {
    static let shared = HapticManager()

    private var engine: CHHapticEngine?

    private init() {
        prepareEngine()
    }

    // MARK: - Simple Feedback

    /// Light tap for button presses, toggles, navigation.
    func lightTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Medium impact for completing a check-in or quick-log quest.
    func questCheckIn() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Strong thud for timer quest completion.
    func questTimerComplete() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    /// Success notification for quest completion with XP award.
    func questCompleted() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Triple-pulse celebration for level-up.
    func levelUp() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            generator.impactOccurred(intensity: 0.8)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            generator.impactOccurred(intensity: 1.0)
        }
    }

    /// Satisfying "ring close" rumble when a Faith Ring fills to 100%.
    func ringClosed() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    /// Warning buzz when streak is at risk.
    func streakWarning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    /// Badge unlock celebration.
    func badgeUnlocked() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Selection tick for picker changes, tab switches.
    func selectionTick() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    // MARK: - Core Haptics (Advanced Patterns)

    /// Rich "XP rain" pattern using Core Haptics for big XP awards (50+).
    func xpCelebration() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            questCompleted()
            return
        }
        prepareEngine()

        var events: [CHHapticEvent] = []

        // Rising crescendo of taps
        for i in 0..<6 {
            let time = Double(i) * 0.08
            let intensity = CHHapticEventParameter(
                parameterID: .hapticIntensity,
                value: Float(i + 1) / 6.0
            )
            let sharpness = CHHapticEventParameter(
                parameterID: .hapticSharpness,
                value: Float(i) / 8.0
            )
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: time
            ))
        }

        // Final boom
        events.append(CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3),
            ],
            relativeTime: 0.5,
            duration: 0.2
        ))

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            questCompleted() // Fallback
        }
    }

    // MARK: - Engine

    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            try engine?.start()
        } catch {
            engine = nil
        }
    }
}
