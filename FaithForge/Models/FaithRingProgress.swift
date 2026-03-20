// FaithRingProgress.swift
// FaithForge
//
// SwiftData model tracking daily XP per Faith Ring category.

import Foundation
import SwiftData

@Model
final class FaithRingProgress {
    var id: UUID = UUID()
    var ringCategoryRaw: String = RingCategory.word.rawValue
    var dailyXP: Int = 0
    /// The calendar day this progress belongs to (start of day).
    var date: Date = Date()

    init(ringCategory: RingCategory, date: Date = Date()) {
        self.id = UUID()
        self.ringCategoryRaw = ringCategory.rawValue
        self.dailyXP = 0
        self.date = Calendar.current.startOfDay(for: date)
    }

    var ringCategory: RingCategory {
        get { RingCategory(rawValue: ringCategoryRaw) ?? .word }
        set { ringCategoryRaw = newValue.rawValue }
    }

    /// 0.0 – 1.0 fill fraction for the ring.
    var fillFraction: Double {
        let goal = ringCategory.dailyGoal
        guard goal > 0 else { return 0 }
        return min(Double(dailyXP) / Double(goal), 1.0)
    }
}
