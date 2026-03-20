// FaithForgeApp.swift
// FaithForge
//
// Main app entry point. Configures SwiftData, services, and root navigation.

import SwiftUI
import SwiftData

@main
struct FaithForgeApp: App {
    let modelContainer: ModelContainer

    // Services injected via environment
    @State private var authService = FirebaseAuthStub()
    @State private var healthKitManager = HealthKitManager()

    init() {
        // Configure SwiftData with all models
        let schema = Schema([
            UserProfile.self,
            DailyQuest.self,
            Badge.self,
            FaithRingProgress.self,
            LeaderboardEntry.self,
            FriendConnection.self,
            CommunityChallenge.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // TODO: Firebase — call FirebaseApp.configure() here when adding real Firebase SDK
        // TODO: RevenueCat — call Purchases.configure(withAPIKey:) here

        // Register notification categories
        NotificationService.shared.registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
                .environment(healthKitManager)
                .task {
                    // Request notification permission on first launch
                    await NotificationService.shared.requestAuthorization()
                }
        }
        .modelContainer(modelContainer)
    }
}
