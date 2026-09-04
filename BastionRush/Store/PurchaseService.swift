import Foundation
import Observation
import RevenueCat

@MainActor
@Observable
final class PurchaseService {
    static let entitlementID = "commander_pack"

    var isPremium = false
    var isLoading = false
    var package: Package?
    var message: String?

    static var isConfigured: Bool {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String else { return false }
        return key.hasPrefix("appl_") && !key.contains("your_")
    }

    static func configureIfPossible() {
        guard isConfigured,
              let key = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String else { return }
        Purchases.logLevel = _isDebugAssertConfiguration() ? .debug : .info
        Purchases.configure(withAPIKey: key)
    }

    func refresh() async {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-premium") {
            isPremium = true
            return
        }
        #endif
        guard Self.isConfigured else {
            message = "Add your RevenueCat public iOS key in Config/Secrets.xcconfig to test real purchases."
            return
        }
        do {
            async let info = Purchases.shared.customerInfo()
            async let offerings = Purchases.shared.offerings()
            let (customerInfo, availableOfferings) = try await (info, offerings)
            isPremium = customerInfo.entitlements.active[Self.entitlementID] != nil
            package = availableOfferings.current?.lifetime
                ?? availableOfferings.current?.availablePackages.first
            message = package == nil ? "No package is attached to the current RevenueCat offering." : nil
        } catch {
            message = error.localizedDescription
        }
    }

    func purchase() async {
        guard let package else {
            message = "The Commander Pack is not available yet."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            isPremium = result.customerInfo.entitlements.active[Self.entitlementID] != nil
            if isPremium { message = nil }
        } catch {
            if let purchaseError = error as? RevenueCat.ErrorCode, purchaseError == .purchaseCancelledError {
                return
            }
            message = error.localizedDescription
        }
    }

    func restore() async {
        guard Self.isConfigured else {
            message = "RevenueCat is not configured in this local build."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let info = try await Purchases.shared.restorePurchases()
            isPremium = info.entitlements.active[Self.entitlementID] != nil
            message = isPremium ? "Commander Pack restored." : "No previous purchase was found."
        } catch {
            message = error.localizedDescription
        }
    }
}
