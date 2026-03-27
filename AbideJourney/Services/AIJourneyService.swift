import Foundation

/// Generates personalized journey content using the Claude API.
/// Falls back to the local NLP-lite keyword matching if the API call fails.
actor AIJourneyService {
    static let shared = AIJourneyService()

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
    /// Returns nil if the API is unavailable or the call fails, signaling
    /// the caller to fall back to local generation.
    func generateJourneyPlan(
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
