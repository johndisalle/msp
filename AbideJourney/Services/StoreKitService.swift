import Foundation
import StoreKit

@MainActor
@Observable
final class StoreKitService {
    static let shared = StoreKitService()

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private var updateListenerTask: Task<Void, Error>?

    nonisolated static let monthlyProductID = "com.abidejourney.premium.monthly"
    nonisolated static let yearlyProductID = "com.abidejourney.premium.yearly"
    nonisolated static let allProductIDs: Set<String> = [monthlyProductID, yearlyProductID]

    var isPremium: Bool {
        !purchasedProductIDs.isEmpty
    }

    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyProductID }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == Self.yearlyProductID }
    }

    private init() {
        updateListenerTask = listenForTransactions()
        Task { await loadProducts() }
    }


    // MARK: - Load Products

    var loadAttempts = 0
    private static let maxRetries = 3

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let loadedProducts = try await Product.products(for: Self.allProductIDs)
            if loadedProducts.isEmpty {
                // Retry with backoff — App Store may not respond immediately in sandbox
                if loadAttempts < Self.maxRetries {
                    loadAttempts += 1
                    let delay = UInt64(loadAttempts) * 2_000_000_000 // 2s, 4s, 6s
                    try? await Task.sleep(nanoseconds: delay)
                    isLoading = false
                    await loadProducts()
                    return
                }
                errorMessage = "Subscription options are currently unavailable. Please check your connection and try again."
            } else {
                loadAttempts = 0
            }
            products = loadedProducts.sorted { $0.price < $1.price }
            isLoading = false
        } catch {
            if loadAttempts < Self.maxRetries {
                loadAttempts += 1
                let delay = UInt64(loadAttempts) * 2_000_000_000
                try? await Task.sleep(nanoseconds: delay)
                isLoading = false
                await loadProducts()
                return
            }
            errorMessage = "Unable to connect to the App Store. Please check your connection and try again."
            isLoading = false
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePurchasedProducts()
            return transaction

        case .userCancelled:
            return nil

        case .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
        await updatePurchasedProducts()
    }

    // MARK: - Check Current Entitlements

    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            }
        }

        purchasedProductIDs = purchased
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if let transaction = try? await self.checkVerified(result) {
                    await transaction.finish()
                    await self.updatePurchasedProducts()
                }
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
