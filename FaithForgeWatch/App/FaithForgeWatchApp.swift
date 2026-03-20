// FaithForgeWatchApp.swift
// FaithForgeWatch
//
// Apple Watch app entry point. Standalone quest view + streak complication.

import SwiftUI
import SwiftData
import FaithForgeShared

@main
struct FaithForgeWatchApp: App {
    let modelContainer: ModelContainer

    init() {
        let schema = SharedSchema.schema()
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create Watch ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
        .modelContainer(modelContainer)
    }
}
