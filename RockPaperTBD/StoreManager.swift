import StoreKit

@Observable
final class StoreManager {
    private(set) var products: [Product] = []
    private(set) var purchasedProductIds: Set<String> = []
    private(set) var isLoading = false

    private var updateTask: Task<Void, Never>?

    static let productIds: Set<String> = [
        "com.outpostai.rockpapertbd.pack.samurai",
        "com.outpostai.rockpapertbd.pack.space",
        "com.outpostai.rockpapertbd.pack.animals",
    ]

    init() {
        updateTask = Task { [weak self] in
            guard let self else { return }
            for await result in Transaction.updates {
                if let transaction = try? result.payloadValue {
                    self.purchasedProductIds.insert(transaction.productID)
                    await transaction.finish()
                }
            }
        }
    }

    deinit {
        updateTask?.cancel()
    }

    func loadProducts() async {
        guard products.isEmpty else { return }
        isLoading = true
        do {
            let storeProducts = try await Product.products(for: Self.productIds)
            products = storeProducts.sorted { $0.displayName < $1.displayName }
        } catch {
            print("Failed to load products: \(error)")
        }
        isLoading = false
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if let transaction = try? verification.payloadValue {
                    purchasedProductIds.insert(transaction.productID)
                    await transaction.finish()
                    return true
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("Purchase failed: \(error)")
        }
        return false
    }

    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? result.payloadValue {
                purchasedProductIds.insert(transaction.productID)
            }
        }
    }

    func isPurchased(_ productId: String) -> Bool {
        purchasedProductIds.contains(productId)
    }
}
