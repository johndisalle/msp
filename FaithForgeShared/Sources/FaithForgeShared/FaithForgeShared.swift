// FaithForgeShared.swift
// FaithForgeShared
//
// Umbrella re-export. Import FaithForgeShared to get all shared models and extensions.

import SwiftData

/// All SwiftData model types in the shared package.
/// Use this to create a ModelContainer that works across all targets.
public enum SharedSchema {
    public static let allModels: [any PersistentModel.Type] = [
        UserProfile.self,
        DailyQuest.self,
        Badge.self,
        FaithRingProgress.self,
    ]

    /// Create a Schema for all shared models.
    public static func schema() -> Schema {
        Schema(allModels)
    }
}
