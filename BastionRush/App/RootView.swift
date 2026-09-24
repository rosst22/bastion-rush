import SwiftUI

struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-launchPaywall")
            || ProcessInfo.processInfo.arguments.contains("-captureReviewPaywall") {
            PaywallView()
        } else if ProcessInfo.processInfo.arguments.contains("-launchArmory") {
            ArmoryView()
        } else if ProcessInfo.processInfo.arguments.contains("-launchGame") {
            GameView()
        } else if ProcessInfo.processInfo.arguments.contains("-skipOnboarding") {
            HomeView()
        } else if hasSeenOnboarding {
            HomeView()
        } else {
            onboarding
        }
        #else
        if hasSeenOnboarding {
            HomeView()
        } else {
            onboarding
        }
        #endif
    }

    private var onboarding: some View {
        OnboardingView {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                hasSeenOnboarding = true
            }
        }
    }
}
