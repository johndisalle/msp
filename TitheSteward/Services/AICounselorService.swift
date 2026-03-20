import Foundation

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: ChatRole
    let content: String
    let timestamp: Date

    init(id: UUID = UUID(), role: ChatRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }

    enum ChatRole: String, Codable {
        case user
        case assistant
        case system
    }
}

@MainActor
class AICounselorService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var error: String?

    private let apiKey: String?

    static let systemPrompt = """
    You are a compassionate Christian financial counselor within the Tithe Steward app. \
    Your role is to provide Scripture-based guidance on tithing, budgeting, debt freedom, \
    and generous living.

    Guidelines:
    - Always ground advice in Biblical principles and specific Scripture references
    - Be encouraging and grace-filled, never condemning
    - Provide practical, actionable financial steps alongside spiritual wisdom
    - When discussing tithing, affirm it as worship, not obligation
    - Address debt with hope, referencing Proverbs 22:7 and God's provision
    - Encourage generosity as a spiritual discipline
    - If asked about investments or specific financial products, recommend consulting a \
    certified financial planner
    - Keep responses concise (2-3 paragraphs max)
    - End responses with a relevant Scripture verse or short prayer when appropriate

    Topics you can help with:
    - Tithing questions and commitment
    - Budget planning with biblical priorities (tithe first, then needs, then wants)
    - Debt payoff strategies (snowball/avalanche with faith perspective)
    - Generosity and giving beyond the tithe
    - Financial anxiety and trusting God's provision
    - Teaching children about stewardship
    - Marriage and unified financial goals
    """

    init() {
        // API key loaded from environment or keychain
        self.apiKey = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String
    }

    func sendMessage(_ text: String) async {
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        isLoading = true
        error = nil

        // Build conversation for API
        let conversationMessages = messages.map { msg -> [String: String] in
            ["role": msg.role == .user ? "user" : "assistant", "content": msg.content]
        }

        do {
            let response = try await callClaudeAPI(messages: conversationMessages)
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            messages.append(assistantMessage)
        } catch {
            self.error = "Unable to get a response. Please check your connection and try again."
            // Provide a fallback response
            let fallback = ChatMessage(
                role: .assistant,
                content: "I'm having trouble connecting right now. In the meantime, remember: \"Trust in the LORD with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.\" — Proverbs 3:5-6\n\nPlease try again in a moment."
            )
            messages.append(fallback)
        }

        isLoading = false
    }

    private func callClaudeAPI(messages: [[String: String]]) async throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw CounselorError.noAPIKey
        }

        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw CounselorError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1024,
            "system": Self.systemPrompt,
            "messages": messages
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CounselorError.apiError
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String else {
            throw CounselorError.parseError
        }

        return text
    }

    func clearChat() {
        messages.removeAll()
        error = nil
    }

    enum CounselorError: LocalizedError {
        case noAPIKey
        case invalidURL
        case apiError
        case parseError

        var errorDescription: String? {
            switch self {
            case .noAPIKey: return "API key not configured"
            case .invalidURL: return "Invalid API URL"
            case .apiError: return "Failed to get response from AI"
            case .parseError: return "Failed to parse response"
            }
        }
    }
}
