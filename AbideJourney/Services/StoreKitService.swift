import Foundation
import StoreKit

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

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let requestedIDs = Self.allProductIDs
            print("[StoreKit] Requesting products for IDs: \(requestedIDs)")
            let loadedProducts = try await Product.products(for: requestedIDs)
            print("[StoreKit] Loaded \(loadedProducts.count) products:")
            for product in loadedProducts {
                print("[StoreKit]   - \(product.id): \(product.displayName) (\(product.displayPrice))")
            }
            if loadedProducts.isEmpty {
                print("[StoreKit] WARNING: No products returned. Check that the StoreKit Configuration file is set in the scheme (Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration).")
            }
            products = loadedProducts.sorted { $0.price < $1.price }
            isLoading = false
        } catch {
            print("[StoreKit] ERROR loading products: \(error)")
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
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
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
