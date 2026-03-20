import Foundation
import SwiftData

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
    @Published var currentSession: ChatSession?
    @Published var sessions: [ChatSession] = []

    private let apiKey: String?
    private var modelContext: ModelContext?

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
        self.apiKey = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSessions()
    }

    // MARK: - Session Management

    func loadSessions() {
        guard let modelContext = modelContext else { return }
        let descriptor = FetchDescriptor<ChatSession>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        sessions = (try? modelContext.fetch(descriptor)) ?? []
    }

    func startNewSession() {
        let session = ChatSession()
        if let modelContext = modelContext, let profile = fetchProfile() {
            session.userProfile = profile
            modelContext.insert(session)
            try? modelContext.save()
        }
        currentSession = session
        messages = []
        loadSessions()
    }

    func loadSession(_ session: ChatSession) {
        currentSession = session
        messages = session.messages
    }

    func deleteSession(_ session: ChatSession) {
        if currentSession?.persistentModelID == session.persistentModelID {
            currentSession = nil
            messages = []
        }
        modelContext?.delete(session)
        try? modelContext?.save()
        loadSessions()
    }

    // MARK: - Messaging

    func sendMessage(_ text: String) async {
        // Create session on first message if needed
        if currentSession == nil {
            startNewSession()
        }

        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        currentSession?.appendMessage(userMessage)

        // Generate title from first message
        if messages.filter({ $0.role == .user }).count == 1 {
            currentSession?.generateTitle()
        }
        try? modelContext?.save()

        isLoading = true
        error = nil

        // Build conversation for API
        let conversationMessages = messages.map { msg -> [String: String] in
            ["role": msg.role == .user ? "user" : "assistant", "content": msg.content]
        }

        let assistantMessage: ChatMessage
        do {
            let personalizedPrompt = buildPersonalizedPrompt()
            let response = try await callClaudeAPI(messages: conversationMessages, systemPrompt: personalizedPrompt)
            assistantMessage = ChatMessage(role: .assistant, content: response)
        } catch {
            self.error = "Unable to get a response. Please check your connection and try again."
            assistantMessage = ChatMessage(
                role: .assistant,
                content: "I'm having trouble connecting right now. In the meantime, remember: \"Trust in the LORD with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.\" — Proverbs 3:5-6\n\nPlease try again in a moment."
            )
        }

        messages.append(assistantMessage)
        currentSession?.appendMessage(assistantMessage)
        try? modelContext?.save()
        loadSessions()
        isLoading = false
    }

    // MARK: - Personalized Context

    private func fetchProfile() -> UserProfile? {
        guard let modelContext = modelContext else { return nil }
        let descriptor = FetchDescriptor<UserProfile>()
        return (try? modelContext.fetch(descriptor))?.first
    }

    func buildPersonalizedPrompt() -> String {
        guard let modelContext = modelContext else { return Self.systemPrompt }

        var context: [String] = []

        // Tithe data
        let titheService = TitheCalculatorService(modelContext: modelContext)
        if let profile = fetchProfile() {
            let score = titheService.calculateGenerosityScore(for: profile)
            let givenMonth = score.totalGivenThisMonth
            let target = score.monthlyTitheTarget
            let remaining = score.remainingToTithe
            let level = score.level.rawValue
            let progress = Int(score.progressToTithe * 100)

            context.append("""
            User's Tithe Status:
            - Monthly income: \(profile.monthlyIncome.currencyFormatted)
            - Tithe target (10%): \(target.currencyFormatted)
            - Given this month: \(givenMonth.currencyFormatted) (\(progress)% of tithe)
            - Remaining to tithe: \(remaining.currencyFormatted)
            - Generosity level: \(level)
            - Given this year: \(score.totalGivenThisYear.currencyFormatted)
            - Tithing commitment: \(profile.tithingCommitment.rawValue)
            """)

            // Budget data
            let budgetService = BudgetService(modelContext: modelContext)
            let categories = budgetService.fetchCategories()
            if !categories.isEmpty {
                let totalBudgeted = budgetService.totalBudgeted(categories)
                let totalSpent = budgetService.totalSpentThisMonth()
                let remaining = totalBudgeted - totalSpent

                context.append("""
                User's Budget Status:
                - Total budgeted: \(totalBudgeted.currencyFormatted)/month
                - Spent this month: \(totalSpent.currencyFormatted)
                - Budget remaining: \(remaining.currencyFormatted)
                """)
            }

            // Debt data
            let debtService = DebtService(modelContext: modelContext)
            let debts = debtService.fetchDebts()
            if !debts.isEmpty {
                let totalDebt = debtService.totalDebt(debts)
                let progress = debtService.overallProgress(debts)
                let minimumPayments = debtService.totalMinimumPayments(debts)

                context.append("""
                User's Debt Status:
                - Total remaining debt: \(totalDebt.currencyFormatted)
                - Debt payoff progress: \(Int(progress * 100))%
                - Number of debts: \(debts.count)
                - Total minimum payments: \(minimumPayments.currencyFormatted)/month
                """)
            } else {
                context.append("User's Debt Status: Debt-free! Praise God.")
            }

            // Recurring giving
            let givingService = GivingService(modelContext: modelContext)
            let recurringTotal = givingService.monthlyRecurringTotal()
            if recurringTotal > 0 {
                let gifts = givingService.fetchRecurringGifts().filter { $0.isActive }
                context.append("""
                User's Recurring Giving:
                - Monthly recurring total: \(recurringTotal.currencyFormatted)
                - Active recurring gifts: \(gifts.count)
                """)
            }
        }

        if context.isEmpty {
            return Self.systemPrompt
        }

        return Self.systemPrompt + "\n\n" + """
        IMPORTANT: The following is the user's current financial data from the app. \
        Use this to personalize your advice. Reference specific numbers when relevant, \
        but don't overwhelm — weave data naturally into your guidance.

        """ + context.joined(separator: "\n\n")
    }

    // MARK: - API

    private func callClaudeAPI(messages: [[String: String]], systemPrompt: String) async throws -> String {
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
            "system": systemPrompt,
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
        if let session = currentSession {
            deleteSession(session)
        }
        messages.removeAll()
        currentSession = nil
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
