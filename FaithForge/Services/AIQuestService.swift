// AIQuestService.swift
// FaithForge
//
// AI-powered quest generation using the user's weak areas, history, and preferences.
// Supports OpenAI-compatible APIs (Claude, GPT, or self-hosted).

import Foundation
import SwiftData
import Observation

@Observable
final class AIQuestService {
    private let modelContext: ModelContext

    var isGenerating: Bool = false
    var lastError: String?

    /// API configuration. Set in Settings or from environment.
    var apiBaseURL: String = "https://api.anthropic.com/v1/messages"
    var apiKey: String = "" // Set at runtime; never hardcode
    var modelID: String = "claude-sonnet-4-20250514"

    /// Whether AI generation is enabled (requires API key).
    var isEnabled: Bool {
        !apiKey.isEmpty
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        // Load saved API key from Keychain in production
        // For MVP, user sets it in settings
    }

    // MARK: - Public API

    /// Generate personalized quests for the user.
    /// Falls back to hardcoded quests if AI is unavailable.
    func generateQuests(
        profile: UserProfile,
        count: Int = 5,
        existingQuests: [DailyQuest] = []
    ) async -> [QuestManager.QuestTemplate] {
        guard isEnabled else {
            return fallbackQuests(profile: profile, count: count)
        }

        await MainActor.run {
            isGenerating = true
            lastError = nil
        }

        do {
            let prompt = buildPrompt(profile: profile, count: count, existingQuests: existingQuests)
            let response = try await callAPI(prompt: prompt)
            let templates = parseResponse(response)

            await MainActor.run { isGenerating = false }

            return templates.isEmpty
                ? fallbackQuests(profile: profile, count: count)
                : templates
        } catch {
            await MainActor.run {
                isGenerating = false
                lastError = error.localizedDescription
            }
            return fallbackQuests(profile: profile, count: count)
        }
    }

    // MARK: - Prompt Builder

    private func buildPrompt(
        profile: UserProfile,
        count: Int,
        existingQuests: [DailyQuest]
    ) -> String {
        let weakAreas = profile.weakAreas.isEmpty
            ? "no specific weak areas identified"
            : profile.weakAreas.joined(separator: ", ")

        let level = profile.level.rawValue
        let streak = profile.currentStreak
        let goal = profile.dailyGoal.rawValue

        let recentTitles = existingQuests
            .prefix(10)
            .map { $0.title }
            .joined(separator: ", ")

        return """
        You are a Christian discipleship coach generating daily spiritual quests \
        for a gamified habit-building app called FaithForge.

        USER PROFILE:
        - Faith Level: \(level)
        - Current Streak: \(streak) days
        - Daily Goal Intensity: \(goal)
        - Weak Areas (needs growth): \(weakAreas)
        - Recent Quests (avoid repeats): \(recentTitles.isEmpty ? "none" : recentTitles)

        Generate exactly \(count) quests. Each quest must be a JSON object with:
        - "title": short quest name (3-6 words)
        - "description": one sentence explaining the quest
        - "category": one of "The Word", "Prayer", "Mission", "Rest in God"
        - "type": one of "Timer", "Check-in", "Reflection", "Quick Log"
        - "xpReward": integer 20-50 based on effort
        - "timerDuration": integer seconds (only for Timer type, 0 otherwise)

        GUIDELINES:
        - Prioritize the user's weak areas with 60% of quests
        - Match quest difficulty to the user's level
        - For beginners, keep quests simple and encouraging
        - For advanced users, include deeper spiritual challenges
        - Timer durations: 180s (easy), 300s (medium), 600s (challenging)
        - Always be biblically grounded and denominationally neutral
        - Vary quest types across the set

        Respond ONLY with a JSON array of quest objects. No other text.
        """
    }

    // MARK: - API Call

    private func callAPI(prompt: String) async throws -> String {
        guard let url = URL(string: apiBaseURL) else {
            throw AIQuestError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "model": modelID,
            "max_tokens": 1024,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw AIQuestError.apiError(statusCode: statusCode)
        }

        // Parse Anthropic response format
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            throw AIQuestError.invalidResponse
        }

        return text
    }

    // MARK: - Response Parser

    private func parseResponse(_ response: String) -> [QuestManager.QuestTemplate] {
        // Extract JSON array from response (handle markdown code blocks)
        var jsonString = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if jsonString.hasPrefix("```") {
            jsonString = jsonString
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let data = jsonString.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        return array.compactMap { dict -> QuestManager.QuestTemplate? in
            guard let title = dict["title"] as? String,
                  let description = dict["description"] as? String,
                  let categoryStr = dict["category"] as? String,
                  let typeStr = dict["type"] as? String,
                  let xpReward = dict["xpReward"] as? Int else {
                return nil
            }

            guard let category = QuestCategory(rawValue: categoryStr),
                  let type = QuestType(rawValue: typeStr) else {
                return nil
            }

            let timerDuration = dict["timerDuration"] as? Int ?? 0

            return QuestManager.QuestTemplate(
                title: title,
                description: description,
                category: category,
                type: type,
                xpReward: min(max(xpReward, 10), 100), // Clamp XP
                timerDuration: type == .timer ? max(timerDuration, 60) : 0
            )
        }
    }

    // MARK: - Fallback (Personalized from Hardcoded Pool)

    private func fallbackQuests(profile: UserProfile, count: Int) -> [QuestManager.QuestTemplate] {
        var pool = QuestManager.sampleQuests

        // Prioritize weak areas
        let weakCategories = profile.weakAreas.compactMap { QuestCategory(rawValue: $0) }
        if !weakCategories.isEmpty {
            let weakQuests = pool.filter { weakCategories.contains($0.category) }
            let otherQuests = pool.filter { !weakCategories.contains($0.category) }
            // 60% weak area quests, 40% other
            let weakCount = Int(ceil(Double(count) * 0.6))
            let otherCount = count - weakCount
            pool = Array(weakQuests.shuffled().prefix(weakCount))
                + Array(otherQuests.shuffled().prefix(otherCount))
        }

        return Array(pool.shuffled().prefix(count))
    }
}

// MARK: - Errors

enum AIQuestError: LocalizedError {
    case invalidURL
    case apiError(statusCode: Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL configuration."
        case .apiError(let code):
            return "API returned status code \(code)."
        case .invalidResponse:
            return "Could not parse AI response."
        }
    }
}
