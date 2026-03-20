// FaithRingProgress.swift
// FaithForgeShared

import Foundation
import SwiftData

@Model
public final class FaithRingProgress {
    public var id: UUID = UUID()
    public var ringCategoryRaw: String = RingCategory.word.rawValue
    public var dailyXP: Int = 0
    public var date: Date = Date()

    public init(ringCategory: RingCategory, date: Date = Date()) {
        self.id = UUID()
        self.ringCategoryRaw = ringCategory.rawValue
        self.dailyXP = 0
        self.date = Calendar.current.startOfDay(for: date)
    }

    public var ringCategory: RingCategory {
        get { RingCategory(rawValue: ringCategoryRaw) ?? .word }
        set { ringCategoryRaw = newValue.rawValue }
    }

    public var fillFraction: Double {
        let goal = ringCategory.dailyGoal
        guard goal > 0 else { return 0 }
        return min(Double(dailyXP) / Double(goal), 1.0)
    }
}
