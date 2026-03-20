import Foundation
import PassKit

/// Manages real payments to churches/ministries via Stripe Connect.
/// Churches onboard via Stripe Express accounts; donors pay via Apple Pay or card.
/// Platform takes a configurable application fee (default 1.5%) on each transaction.
@MainActor
class StripeConnectService: ObservableObject {
    @Published var isProcessing = false
    @Published var lastError: String?
    @Published var lastPaymentResult: PaymentResult?

    private let baseURL: String
    private let publishableKey: String

    static let platformFeePercent: Decimal = Decimal(string: "0.015")! // 1.5%

    struct PaymentResult {
        let id: String
        let amount: Decimal
        let recipientName: String
        let status: PaymentStatus
        let receiptURL: String?
    }

    enum PaymentStatus: String {
        case succeeded
        case processing
        case failed
        case requiresAction = "requires_action"
    }

    struct ConnectedAccount: Codable, Identifiable {
        let id: String
        let name: String
        let stripeAccountId: String
        let isVerified: Bool
        let category: String
    }

    init() {
        self.baseURL = Bundle.main.object(forInfoDictionaryKey: "STRIPE_API_BASE_URL") as? String ?? ""
        self.publishableKey = Bundle.main.object(forInfoDictionaryKey: "STRIPE_PUBLISHABLE_KEY") as? String ?? ""
    }

    // MARK: - Search Connected Ministries

    func searchConnectedMinistries(query: String) async throws -> [ConnectedAccount] {
        guard !baseURL.isEmpty else { throw PaymentError.notConfigured }

        var components = URLComponents(string: "\(baseURL)/api/v1/ministries/search")!
        components.queryItems = [URLQueryItem(name: "q", value: query)]

        let (data, response) = try await URLSession.shared.data(from: components.url!)
        try validateResponse(response)

        return try JSONDecoder().decode([ConnectedAccount].self, from: data)
    }

    // MARK: - Create Payment Intent

    func createPaymentIntent(
        amount: Decimal,
        recipientStripeAccountId: String,
        recipientName: String,
        category: GivingCategory,
        donorEmail: String?
    ) async throws -> PaymentIntentResponse {
        guard !baseURL.isEmpty else { throw PaymentError.notConfigured }

        let url = URL(string: "\(baseURL)/api/v1/payments/create-intent")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let platformFee = NSDecimalNumber(decimal: amount * Self.platformFeePercent).intValue
        let amountCents = NSDecimalNumber(decimal: amount * 100).intValue

        let body: [String: Any] = [
            "amount": amountCents,
            "currency": "usd",
            "destination": recipientStripeAccountId,
            "application_fee_amount": platformFee,
            "metadata": [
                "category": category.rawValue,
                "recipient_name": recipientName,
                "donor_email": donorEmail ?? "",
                "source": "tithe_steward_ios"
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        return try JSONDecoder().decode(PaymentIntentResponse.self, from: data)
    }

    struct PaymentIntentResponse: Codable {
        let clientSecret: String
        let paymentIntentId: String
        let status: String
    }

    // MARK: - Confirm with Apple Pay

    func confirmWithApplePay(
        clientSecret: String,
        payment: PKPayment,
        amount: Decimal,
        recipientName: String
    ) async throws -> PaymentResult {
        guard !baseURL.isEmpty else { throw PaymentError.notConfigured }

        isProcessing = true
        defer { isProcessing = false }

        let url = URL(string: "\(baseURL)/api/v1/payments/confirm-apple-pay")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let tokenData = payment.token.paymentData.base64EncodedString()

        let body: [String: Any] = [
            "client_secret": clientSecret,
            "payment_method_data": [
                "type": "card",
                "apple_pay_token": tokenData
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let confirmResponse = try JSONDecoder().decode(ConfirmResponse.self, from: data)

        let result = PaymentResult(
            id: confirmResponse.paymentIntentId,
            amount: amount,
            recipientName: recipientName,
            status: PaymentStatus(rawValue: confirmResponse.status) ?? .failed,
            receiptURL: confirmResponse.receiptURL
        )

        lastPaymentResult = result
        return result
    }

    struct ConfirmResponse: Codable {
        let paymentIntentId: String
        let status: String
        let receiptURL: String?
    }

    // MARK: - Confirm with Card

    func confirmWithCard(
        clientSecret: String,
        cardNumber: String,
        expMonth: Int,
        expYear: Int,
        cvc: String,
        amount: Decimal,
        recipientName: String
    ) async throws -> PaymentResult {
        guard !baseURL.isEmpty else { throw PaymentError.notConfigured }

        isProcessing = true
        defer { isProcessing = false }

        let url = URL(string: "\(baseURL)/api/v1/payments/confirm-card")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "client_secret": clientSecret,
            "payment_method_data": [
                "type": "card",
                "card": [
                    "number": cardNumber,
                    "exp_month": expMonth,
                    "exp_year": expYear,
                    "cvc": cvc
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let confirmResponse = try JSONDecoder().decode(ConfirmResponse.self, from: data)

        let result = PaymentResult(
            id: confirmResponse.paymentIntentId,
            amount: amount,
            recipientName: recipientName,
            status: PaymentStatus(rawValue: confirmResponse.status) ?? .failed,
            receiptURL: confirmResponse.receiptURL
        )

        lastPaymentResult = result
        return result
    }

    // MARK: - Payment History

    func fetchPaymentHistory() async throws -> [PaymentHistoryItem] {
        guard !baseURL.isEmpty else { throw PaymentError.notConfigured }

        let url = URL(string: "\(baseURL)/api/v1/payments/history")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateResponse(response)

        return try JSONDecoder().decode([PaymentHistoryItem].self, from: data)
    }

    struct PaymentHistoryItem: Codable, Identifiable {
        let id: String
        let amount: Int // cents
        let recipientName: String
        let category: String
        let status: String
        let createdAt: String
        let receiptURL: String?

        var amountDecimal: Decimal {
            Decimal(amount) / 100
        }
    }

    // MARK: - Apple Pay Payment Request

    func createApplePayRequest(amount: Decimal, recipientName: String) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.com.tithesteward.app"
        request.supportedNetworks = [.visa, .masterCard, .amex, .discover]
        request.merchantCapabilities = .threeDSecure
        request.countryCode = "US"
        request.currencyCode = "USD"

        let fee = amount * Self.platformFeePercent
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Gift to \(recipientName)", amount: NSDecimalNumber(decimal: amount - fee)),
            PKPaymentSummaryItem(label: "Processing Fee", amount: NSDecimalNumber(decimal: fee)),
            PKPaymentSummaryItem(label: "Tithe Steward", amount: NSDecimalNumber(decimal: amount)),
        ]
        return request
    }

    // MARK: - Helpers

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PaymentError.networkError
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw PaymentError.serverError(httpResponse.statusCode)
        }
    }

    enum PaymentError: LocalizedError {
        case notConfigured
        case networkError
        case serverError(Int)
        case paymentDeclined
        case invalidCard

        var errorDescription: String? {
            switch self {
            case .notConfigured: return "Payment service is not configured. Please check your settings."
            case .networkError: return "Network error. Please check your connection."
            case .serverError(let code): return "Server error (\(code)). Please try again."
            case .paymentDeclined: return "Payment was declined. Please try a different payment method."
            case .invalidCard: return "Invalid card details. Please check and try again."
            }
        }
    }
}
