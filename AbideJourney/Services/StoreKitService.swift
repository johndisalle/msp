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

    static let monthlyProductID = "com.abidejourney.premium.monthly"
    static let yearlyProductID = "com.abidejourney.premium.yearly"
    static let allProductIDs: Set<String> = [monthlyProductID, yearlyProductID]

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

    nonisolated deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let requestedIDs = Self.allProductIDs
            print("[StoreKit] Requesting products: \(requestedIDs)")
            let loadedProducts = try await Product.products(for: requestedIDs)
            print("[StoreKit] Loaded \(loadedProducts.count) products: \(loadedProducts.map { $0.id })")
            if loadedProducts.isEmpty {
                errorMessage = "No subscription products available. Please check that Products.storekit is set in your scheme's StoreKit Configuration."
            }
            products = loadedProducts.sorted { $0.price < $1.price }
            isLoading = false
        } catch {
            print("[StoreKit] Error loading products: \(error)")
            errorMessage = "Failed to load products: \(error.localizedDescription)"
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
