import Foundation
import Observation
import RevenueCat

@Observable
@MainActor
class StoreViewModel {
    var offerings: Offerings?
    var isPremium: Bool = false
    var isLoading: Bool = false
    var isPurchasing: Bool = false
    var error: String?
    var userCancelledPurchase: Bool = false

    private static var isConfigured: Bool {
        !Config.EXPO_PUBLIC_REVENUECAT_IOS_API_KEY.isEmpty || !Config.EXPO_PUBLIC_REVENUECAT_TEST_API_KEY.isEmpty
    }

    init() {
        guard Self.isConfigured else { return }
        Task { await listenForUpdates() }
        Task { await fetchOfferings() }
    }

    private func listenForUpdates() async {
        guard Self.isConfigured else { return }
        for await info in Purchases.shared.customerInfoStream {
            self.isPremium = info.entitlements["Premium"]?.isActive == true
        }
    }

    func fetchOfferings() async {
        guard Self.isConfigured else { return }
        isLoading = true
        do {
            let fetched = try await Purchases.shared.offerings()
            offerings = fetched
            debugLogOfferings(fetched)
        } catch {
            self.error = error.localizedDescription
            print("[StoreVM] Failed to fetch offerings: \(error)")
        }
        isLoading = false
    }

    private func debugLogOfferings(_ offerings: Offerings) {
        print("[StoreVM] === OFFERINGS DEBUG ===")
        print("[StoreVM] Current offering: \(offerings.current?.identifier ?? "nil")")
        if let current = offerings.current {
            print("[StoreVM] Available packages (\(current.availablePackages.count)):")
            for pkg in current.availablePackages {
                print("[StoreVM]   - id: \(pkg.identifier), type: \(pkg.packageType), productID: \(pkg.storeProduct.productIdentifier), period: \(pkg.storeProduct.subscriptionPeriod?.unit.rawValue ?? -1)")
            }
        }
        for (key, offering) in offerings.all {
            print("[StoreVM] Offering '\(key)': \(offering.availablePackages.count) packages")
            for pkg in offering.availablePackages {
                print("[StoreVM]   - id: \(pkg.identifier), productID: \(pkg.storeProduct.productIdentifier)")
            }
        }
        print("[StoreVM] === END DEBUG ===")
    }

    func purchase(package: Package) async {
        guard Self.isConfigured else { return }
        isPurchasing = true
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled {
                userCancelledPurchase = true
            } else {
                isPremium = result.customerInfo.entitlements["Premium"]?.isActive == true
            }
        } catch ErrorCode.purchaseCancelledError {
            userCancelledPurchase = true
        } catch ErrorCode.paymentPendingError {
        } catch ErrorCode.productAlreadyPurchasedError {
            await checkStatus()
        } catch {
            await checkStatus()
            if !isPremium {
                self.error = error.localizedDescription
            }
        }
        isPurchasing = false
    }

    func restore() async {
        guard Self.isConfigured else { return }
        isLoading = true
        do {
            let info = try await Purchases.shared.restorePurchases()
            isPremium = info.entitlements["Premium"]?.isActive == true
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func checkStatus() async {
        guard Self.isConfigured else { return }
        do {
            let info = try await Purchases.shared.customerInfo()
            isPremium = info.entitlements["Premium"]?.isActive == true
        } catch {
            self.error = error.localizedDescription
        }
    }
}
