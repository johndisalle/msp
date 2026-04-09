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
    nonisolated static let lifetimeProductID = "com.abidejourney.premium.lifetime"
    nonisolated static let allProductIDs: Set<String> = [monthlyProductID, yearlyProductID, lifetimeProductID]

    var isPremium: Bool {
        !purchasedProductIDs.isEmpty
    }

    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyProductID }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == Self.yearlyProductID }
    }

    var lifetimeProduct: Product? {
        products.first { $0.id == Self.lifetimeProductID }
    }

    private init() {
        updateListenerTask = listenForTransactions()
        Task { await loadProducts() }
    }


    // MARK: - Load Products

    private static let maxRetries = 3

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        for attempt in 0...Self.maxRetries {
            do {
                let loadedProducts = try await Product.products(for: Self.allProductIDs)
                if loadedProducts.isEmpty && attempt < Self.maxRetries {
                    try? await Task.sleep(nanoseconds: UInt64(attempt + 1) * 2_000_000_000)
                    continue
                }
                products = loadedProducts.sorted { $0.price < $1.price }
                if loadedProducts.isEmpty {
                    errorMessage = "Subscription options are currently unavailable. Please check your connection and try again."
                }
                isLoading = false
                return
            } catch {
                if attempt < Self.maxRetries {
                    try? await Task.sleep(nanoseconds: UInt64(attempt + 1) * 2_000_000_000)
                    continue
                }
                errorMessage = "Unable to connect to the App Store. Please check your connection and try again."
                isLoading = false
                return
            }
        }
        isLoading = false
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
