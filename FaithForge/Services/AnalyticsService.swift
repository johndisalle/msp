// AnalyticsService.swift
// FaithForge
//
// Centralized analytics event tracking. Uses Firebase Analytics when SDK is added.
// All events are anonymized — no PII is logged.
//
// SETUP:
// 1. Add firebase-ios-sdk via SPM with FirebaseAnalytics
// 2. Uncomment the Firebase Analytics calls below
// 3. Events will appear in Firebase Console > Analytics > Events

import Foundation

import FirebaseAnalytics

enum AnalyticsService {

    // MARK: - Onboarding Events

    static func logOnboardingStarted() {
        log("onboarding_started")
    }

    static func logOnboardingCompleted(dailyGoal: String, weakAreaCount: Int) {
        log("onboarding_completed", parameters: [
            "daily_goal": dailyGoal,
            "weak_area_count": weakAreaCount,
        ])
    }

    static func logSignIn(method: String) {
        log("sign_in", parameters: ["method": method])
    }

    static func logGuestContinue() {
        log("guest_continue")
    }

    // MARK: - Quest Events

    static func logQuestCompleted(category: String, type: String, xpEarned: Int) {
        log("quest_completed", parameters: [
            "category": category,
            "type": type,
            "xp_earned": xpEarned,
        ])
    }

    static func logAllQuestsCompleted(questCount: Int, totalXP: Int) {
        log("all_quests_completed", parameters: [
            "quest_count": questCount,
            "total_xp": totalXP,
        ])
    }

    static func logAIQuestsGenerated(count: Int) {
        log("ai_quests_generated", parameters: ["count": count])
    }

    static func logAIQuestsFailed(error: String) {
        log("ai_quests_failed", parameters: ["error": error])
    }

    // MARK: - XP & Level Events

    static func logXPAwarded(amount: Int, totalXP: Int) {
        log("xp_awarded", parameters: [
            "amount": amount,
            "total_xp": totalXP,
        ])
    }

    static func logLevelUp(newLevel: String, totalXP: Int) {
        log("level_up", parameters: [
            "new_level": newLevel,
            "total_xp": totalXP,
        ])
    }

    static func logRingClosed(ring: String) {
        log("ring_closed", parameters: ["ring": ring])
    }

    static func logAllRingsClosed() {
        log("all_rings_closed")
    }

    // MARK: - Streak Events

    static func logStreakMilestone(streakDays: Int) {
        log("streak_milestone", parameters: ["streak_days": streakDays])
    }

    static func logStreakBroken(previousStreak: Int) {
        log("streak_broken", parameters: ["previous_streak": previousStreak])
    }

    // MARK: - Badge Events

    static func logBadgeUnlocked(badgeName: String) {
        log("badge_unlocked", parameters: ["badge_name": badgeName])
    }

    // MARK: - Social Events

    static func logLeaderboardViewed(period: String) {
        log("leaderboard_viewed", parameters: ["period": period])
    }

    static func logFriendRequestSent() {
        log("friend_request_sent")
    }

    static func logFriendRequestAccepted() {
        log("friend_request_accepted")
    }

    static func logChallengeJoined(challengeType: String) {
        log("challenge_joined", parameters: ["challenge_type": challengeType])
    }

    static func logChallengeCompleted(challengeTitle: String) {
        log("challenge_completed", parameters: ["challenge_title": challengeTitle])
    }

    // MARK: - Premium / Subscription Events

    static func logPaywallViewed() {
        log("paywall_viewed")
    }

    static func logPaywallDismissed() {
        log("paywall_dismissed")
    }

    static func logSubscriptionStarted(tier: String) {
        log("subscription_started", parameters: ["tier": tier])
    }

    static func logSubscriptionRestored() {
        log("subscription_restored")
    }

    // MARK: - Navigation Events

    static func logTabSelected(tab: String) {
        log("tab_selected", parameters: ["tab": tab])
    }

    static func logSettingsOpened() {
        log("settings_opened")
    }

    // MARK: - App Lifecycle

    static func logAppOpened() {
        log("app_opened")
    }

    static func logSessionDuration(seconds: Int) {
        log("session_duration", parameters: ["seconds": seconds])
    }

    // MARK: - Notification Events

    static func logNotificationPermissionGranted() {
        log("notification_permission_granted")
    }

    static func logNotificationPermissionDenied() {
        log("notification_permission_denied")
    }

    static func logNotificationOpened(type: String) {
        log("notification_opened", parameters: ["type": type])
    }

    // MARK: - Private Logger

    private static func log(_ event: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(event, parameters: parameters)

        #if DEBUG
        if let parameters {
            print("[Analytics] \(event): \(parameters)")
        } else {
            print("[Analytics] \(event)")
        }
        #endif
    }
}
