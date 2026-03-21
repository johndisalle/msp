import Foundation

/// Manages AI spiritual director conversations with context from the user's journey data.
/// Sends the full conversation history to the Google Gemini API (free tier) so every
/// response is genuinely contextual — no canned keyword matching.
@Observable
final class SpiritualDirectorService {
    static let shared = SpiritualDirectorService()

    struct Message: Identifiable, Equatable {
        let id = UUID()
        let role: Role
        let content: String
        let timestamp = Date()

        enum Role: String {
            case user
            case assistant
            case system
        }
    }

    private(set) var messages: [Message] = []
    private(set) var isLoading = false
    var error: String?

    /// Read from Info.plist → GEMINI_API_KEY, or fall back to the
    /// GEMINI_API_KEY environment variable set in the Xcode scheme.
    /// Get a free key at https://aistudio.google.com/apikey
    private let apiKey: String? = {
        if let key = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
           !key.isEmpty, !key.hasPrefix("$(") {
            return key
        }
        if let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"],
           !key.isEmpty {
            return key
        }
        return nil
    }()

    private let model = "gemini-2.0-flash"

    private var apiURL: URL? {
        guard let apiKey else { return nil }
        return URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)")
    }

    private init() {}

    // MARK: - Context Building

    struct JourneyContext {
        let userName: String
        let currentDay: Int
        let totalDays: Int
        let journeyTheme: String
        let focusArea: String
        let recentMoods: [String]
        let recentCheckInRatings: [String]
        let recentJournalExcerpts: [String]
        let totalPrayerMinutes: Int
        let streakDays: Int
        let scripturesToday: String
    }

    func buildSystemPrompt(context: JourneyContext) -> String {
        var prompt = """
        You are a warm, wise, and deeply compassionate spiritual director within the Abide Journey app. \
        Your role is to help \(context.userName) grow closer to God through their \(context.journeyTheme) journey.

        IMPORTANT GUIDELINES:
        - Be conversational, warm, and personal. Use their name naturally.
        - Ground your responses in Scripture, but don't be preachy.
        - Ask thoughtful follow-up questions to go deeper.
        - If they're struggling, lead with empathy before advice.
        - Keep responses concise (2-4 paragraphs). This is a chat, not a sermon.
        - Never claim to be God or speak as God. You're a mentor pointing them to God.
        - Be encouraging but honest. Don't offer empty platitudes.
        - Reference their actual journey data naturally — their moods, journal themes, prayer habits — so they feel truly known.
        - Remember what they said earlier in this conversation and build on it.

        THEIR CURRENT JOURNEY:
        - Day \(context.currentDay) of \(context.totalDays) in "\(context.journeyTheme)"
        - Today's focus area: \(context.focusArea)
        - Current streak: \(context.streakDays) days
        - Total prayer time: \(context.totalPrayerMinutes) minutes
        """

        if !context.scripturesToday.isEmpty {
            prompt += "\n- Today's scripture: \(context.scripturesToday)"
        }

        if !context.recentMoods.isEmpty {
            prompt += "\n\nRECENT MOODS: \(context.recentMoods.joined(separator: ", "))"
        }

        if !context.recentCheckInRatings.isEmpty {
            prompt += "\nRECENT CHECK-INS: \(context.recentCheckInRatings.joined(separator: ", "))"
        }

        if !context.recentJournalExcerpts.isEmpty {
            prompt += "\n\nRECENT JOURNAL EXCERPTS (private - reference themes, not exact words):"
            for excerpt in context.recentJournalExcerpts.prefix(3) {
                prompt += "\n- \(excerpt)"
            }
        }

        return prompt
    }

    // MARK: - Conversation

    func startConversation(context: JourneyContext) {
        messages = []
        let systemPrompt = buildSystemPrompt(context: context)
        messages.append(Message(role: .system, content: systemPrompt))

        // Request an AI-generated opening message so even the greeting feels personal
        isLoading = true
        error = nil

        Task { @MainActor in
            let opener = await fetchAIResponse(context: context, forOpener: true)
            messages.append(Message(role: .assistant, content: opener))
            isLoading = false
        }
    }

    func sendMessage(_ text: String, context: JourneyContext) async {
        messages.append(Message(role: .user, content: text))
        isLoading = true
        error = nil

        let response = await fetchAIResponse(context: context)

        messages.append(Message(role: .assistant, content: response))
        isLoading = false
    }

    func clearConversation() {
        messages = []
    }

    // MARK: - Gemini API

    /// Sends the full conversation to the Google Gemini API (free tier).
    /// Falls back to local generation if no API key is configured or the request fails.
    private func fetchAIResponse(context: JourneyContext, forOpener: Bool = false) async -> String {
        guard let apiURL else {
            return forOpener
                ? generateLocalOpener(context: context)
                : generateLocalResponse(userMessage: messages.last(where: { $0.role == .user })?.content ?? "", context: context)
        }

        // Build the Gemini request body.
        // Gemini uses "system_instruction" for the system prompt, and "contents" for the conversation.
        // Gemini roles are "user" and "model" (not "assistant").
        let systemPrompt = messages.first(where: { $0.role == .system })?.content
            ?? buildSystemPrompt(context: context)

        var contents: [[String: Any]] = []
        for message in messages where message.role != .system {
            let geminiRole = message.role == .assistant ? "model" : "user"
            contents.append([
                "role": geminiRole,
                "parts": [["text": message.content]]
            ])
        }

        // For the opener, add a user turn asking for a greeting
        if forOpener {
            contents.append([
                "role": "user",
                "parts": [["text": "Start our conversation with a warm, personal opening message. Reference my journey context naturally."]]
            ])
        }

        let body: [String: Any] = [
            "system_instruction": [
                "parts": [["text": systemPrompt]]
            ],
            "contents": contents,
            "generationConfig": [
                "maxOutputTokens": 512,
                "temperature": 0.85
            ]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return forOpener
                ? generateLocalOpener(context: context)
                : generateLocalResponse(userMessage: messages.last(where: { $0.role == .user })?.content ?? "", context: context)
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 30

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                await MainActor.run {
                    error = "AI response failed (status \(statusCode)). Using offline mode."
                }
                return forOpener
                    ? generateLocalOpener(context: context)
                    : generateLocalResponse(userMessage: messages.last(where: { $0.role == .user })?.content ?? "", context: context)
            }

            // Parse Gemini response:
            // { "candidates": [ { "content": { "parts": [ { "text": "..." } ] } } ] }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let firstPart = parts.first,
               let text = firstPart["text"] as? String {
                return text
            }

            return forOpener
                ? generateLocalOpener(context: context)
                : generateLocalResponse(userMessage: messages.last(where: { $0.role == .user })?.content ?? "", context: context)

        } catch {
            await MainActor.run {
                self.error = "Couldn't reach the server. Using offline mode."
            }
            return forOpener
                ? generateLocalOpener(context: context)
                : generateLocalResponse(userMessage: messages.last(where: { $0.role == .user })?.content ?? "", context: context)
        }
    }

    // MARK: - Local Fallback Responses
    // Used when no API key is configured or the network request fails.

    private func generateLocalOpener(context: JourneyContext) -> String {
        let name = context.userName

        let isStruggling = context.recentMoods.contains("Struggling") || context.recentCheckInRatings.contains("Tough") || context.recentCheckInRatings.contains("Missed")

        if isStruggling {
            return "Hey \(name). I noticed things have been a bit heavy lately, and I want you to know - that's okay. God doesn't expect perfection from you. He just wants your honesty.\n\nWhat's been weighing on you? I'd love to talk through it."
        }

        if context.streakDays >= 7 {
            return "Hey \(name)! \(context.streakDays) days in a row - that's real faithfulness. I can see God working in your consistency.\n\nAs you work through Day \(context.currentDay) of \(context.journeyTheme), what's been stirring in your heart?"
        }

        if context.currentDay <= 3 {
            return "Welcome to the journey, \(name)! I'm so glad you're here. These first few days of \(context.journeyTheme) are about setting a foundation.\n\nNo pressure, no performance - just you and God. What drew you to start this journey?"
        }

        return "Hey \(name)! You're on Day \(context.currentDay) of \(context.journeyTheme). How's it going so far?\n\nI'm here if you want to talk through anything - today's scripture, something from your journal, or whatever's on your mind."
    }

    private func generateLocalResponse(userMessage: String, context: JourneyContext) -> String {
        let name = context.userName
        let message = userMessage.lowercased()

        if message.contains("anxious") || message.contains("anxiety") || message.contains("worried") || message.contains("scared") {
            return "\(name), thank you for sharing that. Anxiety is so real, and God doesn't dismiss it.\n\nPhilippians 4:6-7 says, \"Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God.\" That's not a command to stop feeling - it's an invitation to bring those feelings to Him.\n\nWhat specifically has been making you anxious? Sometimes naming it takes away some of its power."
        }

        if message.contains("doubt") || message.contains("don't believe") || message.contains("not sure") || message.contains("questioning") {
            return "Doubt isn't the opposite of faith, \(name) - it's often the doorway to deeper faith. Even the disciples who walked with Jesus had moments of doubt.\n\nMark 9:24 captures it perfectly: \"I believe; help my unbelief!\" That's one of the most honest prayers in the Bible.\n\nWhat part of your faith feels uncertain right now? Let's explore it together rather than running from it."
        }

        if message.contains("pray") || message.contains("prayer") {
            return "Prayer doesn't have to be fancy, \(name). Some of the most powerful prayers in the Bible are just a few words - \"Lord, help me\" or \"Thank you.\"\n\nYou've spent \(context.totalPrayerMinutes) minutes in prayer on this journey. That matters more than you think.\n\nIs there something specific you'd like to pray about right now? I can suggest a simple framework that might help."
        }

        if message.contains("thankful") || message.contains("grateful") || message.contains("blessed") || message.contains("happy") || message.contains("joy") {
            return "That's beautiful, \(name). Gratitude is one of the most transformative spiritual practices.\n\n1 Thessalonians 5:18 says, \"Give thanks in all circumstances; for this is God's will for you.\" Not for all circumstances, but in them. You're doing exactly that.\n\nWhat's one specific thing God has done recently that you want to remember?"
        }

        if message.contains("struggle") || message.contains("hard") || message.contains("difficult") || message.contains("tough") || message.contains("failing") {
            return "\(name), I hear you. Seasons of struggle don't mean God has left - sometimes they mean He's doing His deepest work.\n\nIsaiah 43:2 promises, \"When you pass through the waters, I will be with you.\" Notice it says \"when,\" not \"if.\" Struggle is part of the journey.\n\nYou've shown up for \(context.currentDay) days already. That's not failure - that's faithfulness in the middle of hard. What feels hardest right now?"
        }

        return "Thank you for sharing that, \(name). I appreciate your honesty.\n\nAs you sit with Day \(context.currentDay) of \(context.journeyTheme), here's something to consider: God is more interested in your heart than your performance. He sees every effort you make.\n\nWhat's one thing from today's scripture (\(context.scripturesToday.isEmpty ? "today's reading" : context.scripturesToday)) that stood out to you? Sometimes the verse that catches your attention is God highlighting something specific for you."
    }
}
