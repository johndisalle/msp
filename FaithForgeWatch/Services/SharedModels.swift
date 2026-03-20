// SharedModels.swift
// FaithForgeWatch
//
// This file is no longer needed — the Watch target now imports FaithForgeShared package.
// All shared models (UserProfile, DailyQuest, Badge, FaithRingProgress) and extensions
// (Date helpers, timer formatting, VerseOfTheDay) come from FaithForgeShared.
//
// Setup in Xcode:
// 1. File → Add Package Dependencies → Add Local → select FaithForgeShared/
// 2. Add FaithForgeShared to FaithForgeWatch target
// 3. Add FaithForgeShared to FaithForgeWidgets target
// 4. Add FaithForgeShared to FaithForge (main app) target
// 5. Remove model files from FaithForge/Models/ target membership (they live in the package now)
//    OR keep them as the "source of truth" and only use the package for Watch/Widget.
//
// For the simplest migration path, keep FaithForge/Models/ for the main app and use
// FaithForgeShared for Watch and Widget targets only. Both define the same @Model types
// so they can share the same SwiftData store via App Groups.
