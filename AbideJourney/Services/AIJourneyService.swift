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
        (Bundle.main.object(forInfoDictionaryKey: "APP_SECRET") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }()

    // Direct API key fallback removed for security — all API calls go through Cloud Function

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

    /// Generates a personalized journey plan from the user's description via Cloud Function.
    /// Returns nil for local fallback generation if Cloud Function is not configured.
    func generateJourneyPlan(
        description: String,
        userName: String,
        maturityLevel: String
    ) async -> AIJourneyPlan? {
        return await generateViaCloudFunction(description: description)
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

}
