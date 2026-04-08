import Foundation
import UIKit

/// Generates personalized journey content using a Firebase Cloud Function proxy.
/// Falls back to direct API call if Firebase is not configured, then to local generation.
actor AIJourneyService {
    static let shared = AIJourneyService()

    /// Firebase Cloud Function URL — set this after deploying your functions.
    /// Format: "https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/generateJourneyHTTP"
    private let cloudFunctionURL: String? = {
        Bundle.main.object(forInfoDictionaryKey: "CLOUD_FUNCTION_URL") as? String
    }()

    /// App secret for authenticating with the Cloud Function (must match APP_SECRET in .env).
    private let appSecret: String? = {
        Bundle.main.object(forInfoDictionaryKey: "APP_SECRET") as? String
    }()

    /// Direct API key — only used as fallback if Cloud Function is not configured.
    /// Remove this entirely once Cloud Function is deployed.
    private let apiKey: String? = {
        Bundle.main.object(forInfoDictionaryKey: "CLAUDE_API_KEY") as? String
    }()

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    struct AIJourneyPlan: Codable {
        let title: String
        let theme: String
        let focusAreas: [String]
        let days: [AIDay]
    }

    struct AIDay: Codable {
        let dayNumber: Int
        let scriptureReference: String
        let scriptureText: String
        let devotionalTitle: String
        let devotionalText: String
        let prayerText: String
        let reflectionPrompt: String
        let actionSteps: [String]
    }

    /// Generates a personalized journey plan from the user's description.
    /// Tries Cloud Function first (secure), then direct API (fallback), then returns nil for local generation.
    func generateJourneyPlan(
        description: String,
        userName: String,
        maturityLevel: String
    ) async -> AIJourneyPlan? {
        // Try Cloud Function proxy first (recommended — API key never leaves your server)
        if let plan = await generateViaCloudFunction(description: description) {
            return plan
        }

        // Fallback to direct API call (remove once Cloud Function is deployed)
        return await generateViaDirectAPI(description: description, userName: userName, maturityLevel: maturityLevel)
    }

    /// Calls the Firebase Cloud Function HTTP proxy to generate a journey.
    private func generateViaCloudFunction(description: String) async -> AIJourneyPlan? {
        guard let urlString = cloudFunctionURL,
              !urlString.isEmpty,
              urlString != "YOUR_CLOUD_FUNCTION_URL",
              let url = URL(string: urlString),
              let secret = appSecret,
              !secret.isEmpty else {
            return nil
        }

        // Unique device ID for rate limiting
        let deviceId = await UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString

        let body: [String: Any] = [
            "description": description,
            "theme": "spiritualGrowth",
            "deviceId": deviceId
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(secret, forHTTPHeaderField: "X-App-Secret")
        request.timeoutInterval = 120 // AI generation can take a while

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            // HTTP endpoint returns the journey JSON directly
            return try JSONDecoder().decode(AIJourneyPlan.self, from: data)
        } catch {
            return nil
        }
    }

    /// Direct API call fallback — remove once Cloud Function is deployed.
    private func generateViaDirectAPI(
        description: String,
        userName: String,
        maturityLevel: String
    ) async -> AIJourneyPlan? {
        guard let apiKey, !apiKey.isEmpty, apiKey != "YOUR_CLAUDE_API_KEY" else {
            return nil // No API key configured — use local fallback
        }

        let systemPrompt = """
        You are a Christian devotional content writer for the app "Abide Journey." \
        Given a user's description of what they're going through, generate a \
        personalized 40-day journey plan.

        The user's spiritual maturity level is: \(maturityLevel).
        Their name is: \(userName).

        Return ONLY valid JSON matching this exact structure (no markdown, no explanation):
        {
          "title": "Journey Title (short, 3-6 words)",
          "theme": "one of: knowingGod, obeyingGod, sharingFaith, bearingFruit, \
        overcomingDoubt, findingPeace, spiritualGrowth, overcomingAnxiety, \
        walkingThroughGrief, leadingLikeJesus, startingOver, healingRelationships, \
        hearingGodsVoice",
          "focusAreas": ["prayer", "scripture", "obedience", "worship", "community", \
        "evangelism", "service"],
          "days": [
            {
              "dayNumber": 1,
              "scriptureReference": "Book Chapter:Verse",
              "scriptureText": "Full verse text (NIV preferred)",
              "devotionalTitle": "Short title (3-6 words)",
              "devotionalText": "3-5 sentence devotional, warm and conversational",
              "prayerText": "A personal prayer addressing God directly",
              "reflectionPrompt": "A thought-provoking question",
              "actionSteps": ["Practical step 1", "Practical step 2"]
            }
          ]
        }

        Guidelines:
        - Generate exactly 40 days
        - Each day must have exactly 2 action steps
        - Use varied scriptures (no duplicates) from across the Bible
        - Tailor content to the user's specific situation
        - Devotionals should be warm, pastoral, and 3-5 sentences
        - Action steps should be practical and doable in one day
        - Cycle through all 7 focus areas across the 40 days
        - Make reflection prompts personal to their described situation
        """

        let userMessage = """
        Here's what this person is going through:

        "\(description)"

        Please generate their personalized 40-day journey.
        """

        let requestBody: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 16000,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            // Parse the API response to extract the content text
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = json["content"] as? [[String: Any]],
                  let firstBlock = content.first,
                  let text = firstBlock["text"] as? String else {
                return nil
            }

            // Parse the JSON content from Claude's response
            guard let jsonData = text.data(using: .utf8) else { return nil }
            let plan = try JSONDecoder().decode(AIJourneyPlan.self, from: jsonData)
            return plan
        } catch {
            return nil
        }
    }
}
