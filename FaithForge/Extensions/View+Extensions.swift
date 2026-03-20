// View+Extensions.swift
// FaithForge
//
// Reusable View modifiers for consistent styling.

import SwiftUI

// MARK: - Card Modifier

struct FaithCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color("BackgroundSecondary"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

extension View {
    /// Apply the standard FaithForge card style.
    func faithCard() -> some View {
        modifier(FaithCardModifier())
    }
}

// MARK: - Date Helpers

extension Date {
    /// Start of the current calendar day.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Short weekday abbreviation ("Mon", "Tue", etc.).
    var shortWeekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }

    /// Whether this date is the same calendar day as today.
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
}

// MARK: - Time Formatting

extension Int {
    /// Format seconds as "M:SS" for timer display.
    var timerFormatted: String {
        let minutes = self / 60
        let seconds = self % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
