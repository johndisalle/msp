import Foundation

/// Connects to user's bank accounts via Plaid to detect income deposits
/// and auto-calculate tithe suggestions.
@MainActor
class PlaidService: ObservableObject {
    @Published var isLinked = false
    @Published var isLoading = false
    @Published var linkedAccounts: [LinkedAccount] = []
    @Published var recentIncomeDeposits: [IncomeDeposit] = []
    @Published var pendingTitheSuggestion: TitheSuggestion?
    @Published var lastError: String?

    private let baseURL: String

    struct LinkedAccount: Codable, Identifiable {
        let id: String
        let institutionName: String
        let accountName: String
        let accountMask: String
        let accountType: String
        let isActive: Bool
    }

    struct IncomeDeposit: Codable, Identifiable {
        let id: String
        let accountId: String
        let amount: Double
        let name: String
        let date: String
        let category: String
        let isRecurring: Bool

        var amountDecimal: Decimal { Decimal(amount) }

        var suggestedTithe: Decimal {
            amountDecimal * Decimal(string: "0.10")!
        }

        var displayDate: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let parsed = formatter.date(from: date) else { return date }
            formatter.dateStyle = .medium
            return formatter.string(from: parsed)
        }
    }

    struct TitheSuggestion: Identifiable {
        let id = UUID()
        let deposit: IncomeDeposit
        let suggestedAmount: Decimal
        let suggestedRecipient: String?

        var message: String {
            let amountStr = NumberFormatter.localizedString(from: deposit.amount as NSNumber, number: .currency)
            let titheStr = NumberFormatter.localizedString(from: suggestedAmount as NSDecimalNumber, number: .currency)
            return "We noticed a \(amountStr) deposit from \(deposit.name). Your tithe would be \(titheStr). Give now?"
        }
    }

    struct LinkTokenResponse: Codable {
        let linkToken: String
        let expiration: String
    }

    init() {
        self.baseURL = Bundle.main.object(forInfoDictionaryKey: "PLAID_API_BASE_URL") as? String ?? ""
        loadLinkedState()
    }

    // MARK: - Link Flow

    func createLinkToken() async throws -> String {
        guard !baseURL.isEmpty else { throw PlaidError.notConfigured }

        let url = URL(string: "\(baseURL)/api/v1/plaid/create-link-token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "products": ["transactions"],
            "country_codes": ["US"],
            "language": "en"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let tokenResponse = try JSONDecoder().decode(LinkTokenResponse.self, from: data)
        return tokenResponse.linkToken
    }

    func exchangePublicToken(_ publicToken: String) async throws {
        guard !baseURL.isEmpty else { throw PlaidError.notConfigured }

        isLoading = true
        defer { isLoading = false }

        let url = URL(string: "\(baseURL)/api/v1/plaid/exchange-token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["public_token": publicToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        isLinked = true
        UserDefaults.standard.set(true, forKey: "plaid_linked")

        try await fetchAccounts()
    }

    // MARK: - Account Data

    func fetchAccounts() async throws {
        guard !baseURL.isEmpty else { throw PlaidError.notConfigured }

        let url = URL(string: "\(baseURL)/api/v1/plaid/accounts")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateResponse(response)

        linkedAccounts = try JSONDecoder().decode([LinkedAccount].self, from: data)
    }

    // MARK: - Income Detection

    func checkForNewIncome(primaryChurch: String? = nil) async throws {
        guard !baseURL.isEmpty else { throw PlaidError.notConfigured }
        guard isLinked else { return }

        isLoading = true
        defer { isLoading = false }

        let url = URL(string: "\(baseURL)/api/v1/plaid/income-deposits")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateResponse(response)

        recentIncomeDeposits = try JSONDecoder().decode([IncomeDeposit].self, from: data)

        // Generate tithe suggestion from the most recent unprocessed deposit
        if let latest = recentIncomeDeposits.first {
            let processedIds = Set(UserDefaults.standard.stringArray(forKey: "processed_deposit_ids") ?? [])
            if !processedIds.contains(latest.id) {
                pendingTitheSuggestion = TitheSuggestion(
                    deposit: latest,
                    suggestedAmount: latest.suggestedTithe,
                    suggestedRecipient: primaryChurch
                )
            }
        }
    }

    func markDepositProcessed(_ depositId: String) {
        var processed = UserDefaults.standard.stringArray(forKey: "processed_deposit_ids") ?? []
        processed.append(depositId)
        // Keep only last 100 to avoid unbounded growth
        if processed.count > 100 {
            processed = Array(processed.suffix(100))
        }
        UserDefaults.standard.set(processed, forKey: "processed_deposit_ids")
        pendingTitheSuggestion = nil
    }

    func dismissSuggestion() {
        if let suggestion = pendingTitheSuggestion {
            markDepositProcessed(suggestion.deposit.id)
        }
    }

    // MARK: - Unlink

    func unlinkBank() async throws {
        guard !baseURL.isEmpty else { throw PlaidError.notConfigured }

        let url = URL(string: "\(baseURL)/api/v1/plaid/unlink")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        isLinked = false
        linkedAccounts = []
        recentIncomeDeposits = []
        pendingTitheSuggestion = nil
        UserDefaults.standard.set(false, forKey: "plaid_linked")
        UserDefaults.standard.removeObject(forKey: "processed_deposit_ids")
    }

    // MARK: - Helpers

    private func loadLinkedState() {
        isLinked = UserDefaults.standard.bool(forKey: "plaid_linked")
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlaidError.networkError
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw PlaidError.serverError(httpResponse.statusCode)
        }
    }

    enum PlaidError: LocalizedError {
        case notConfigured
        case networkError
        case serverError(Int)
        case notLinked
        case linkExpired

        var errorDescription: String? {
            switch self {
            case .notConfigured: return "Bank connection is not configured."
            case .networkError: return "Network error. Please check your connection."
            case .serverError(let code): return "Server error (\(code)). Please try again."
            case .notLinked: return "No bank account linked. Please connect your bank first."
            case .linkExpired: return "Bank connection expired. Please reconnect."
            }
        }
    }
}
