import SwiftUI

@main
struct BastionRushApp: App {
    @State private var progress = PlayerProgress.load()
    @State private var purchaseService = PurchaseService()

    init() {
        PurchaseService.configureIfPossible()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(progress)
                .environment(purchaseService)
                .preferredColorScheme(.dark)
                .task { await purchaseService.refresh() }
        }
    }
}
