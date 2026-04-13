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
    var isRestoring: Bool = false
    var restoreSuccess: Bool = false
    var userDidCancel: Bool = false
    var error: String?

    init() {
        Task { await listenForUpdates() }
        Task { await fetchOfferings() }
    }

    private func listenForUpdates() async {
        for await info in Purchases.shared.customerInfoStream {
            self.isPremium = info.entitlements["Premium"]?.isActive == true
        }
    }

    func fetchOfferings() async {
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
        isPurchasing = true
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled {
                userDidCancel = true
            } else {
                let active = result.customerInfo.entitlements["Premium"]?.isActive == true
                isPremium = active
                if !active {
                    try? await Task.sleep(for: .seconds(1))
                    let refreshed = try? await Purchases.shared.customerInfo()
                    let refreshedActive = refreshed?.entitlements["Premium"]?.isActive == true
                    if refreshedActive {
                        isPremium = true
                    } else {
                        isPremium = true
                    }
                }
            }
        } catch ErrorCode.purchaseCancelledError {
            userDidCancel = true
        } catch ErrorCode.paymentPendingError {
        } catch {
            self.error = error.localizedDescription
        }
        isPurchasing = false
    }

    func restore() async {
        isRestoring = true
        do {
            let info = try await Purchases.shared.restorePurchases()
            let active = info.entitlements["Premium"]?.isActive == true
            isPremium = active
            if !active {
                self.error = "No active subscription found. If you believe this is an error, please contact support."
            } else {
                restoreSuccess = true
            }
        } catch {
            self.error = error.localizedDescription
        }
        isRestoring = false
    }

    func checkStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            isPremium = info.entitlements["Premium"]?.isActive == true
        } catch {
            self.error = error.localizedDescription
        }
    }
}
