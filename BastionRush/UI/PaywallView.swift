import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchaseService.self) private var purchases
    @State private var legalPage: LegalPage?

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppTheme.navy, Color(red: 0.13, green: 0.09, blue: 0.18)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark").font(.headline.weight(.bold)).frame(width: 38, height: 38)
                                .background(.white.opacity(0.09), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    ZStack {
                        Circle().fill(AppTheme.gold.opacity(0.12)).frame(width: 150, height: 150)
                        Circle().stroke(AppTheme.gold.opacity(0.3), lineWidth: 2).frame(width: 120, height: 120)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 64, weight: .black))
                            .foregroundStyle(AppTheme.gold)
                    }
                    VStack(spacing: 7) {
                        Text("COMMANDER PACK").font(.largeTitle.weight(.black)).multilineTextAlignment(.center)
                        Text("Make the squad yours. No gameplay advantage, no recurring charge.")
                            .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    VStack(spacing: 12) {
                        perk("flame.fill", "Ember squad color", .orange)
                        perk("shield.fill", "Ivory squad color", AppTheme.ivory)
                        perk("medal.fill", "Founding Commander badge", AppTheme.gold)
                        perk("hand.raised.fill", "Support an independent game", AppTheme.cyan)
                    }
                    .gamePanel()

                    if purchases.isPremium {
                        Label("Commander Pack Active", systemImage: "checkmark.seal.fill")
                            .font(.headline.weight(.bold)).foregroundStyle(AppTheme.gold)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(AppTheme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
                    } else {
                        Button { Task { await purchases.purchase() } } label: {
                            HStack {
                                if purchases.isLoading { ProgressView().tint(.white) }
                                Text("Unlock Forever — \(displayPrice)")
                            }
                            .font(.headline.weight(.black))
                            .frame(maxWidth: .infinity).padding(.vertical, 17)
                            .background(AppTheme.cobalt, in: RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)
                        .disabled(purchases.isLoading || purchases.package == nil)
                    }

                    if let message = purchases.message {
                        Text(message)
                            .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    Text("One-time non-consumable purchase. Payment is charged to your Apple ID after confirmation.")
                        .font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    HStack(spacing: 20) {
                        Button("Restore Purchases") { Task { await purchases.restore() } }
                        Button("Privacy") { legalPage = .privacy }
                        Button("Terms") { legalPage = .terms }
                    }
                    .font(.caption.weight(.bold)).foregroundStyle(.secondary)
                }
                .padding(22)
            }
        }
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .sheet(item: $legalPage) { LegalView(page: $0) }
    }

    private var displayPrice: String {
        purchases.package?.storeProduct.localizedPriceString ?? "$3.99"
    }

    private func perk(_ symbol: String, _ text: String, _ color: Color) -> some View {
        HStack(spacing: 13) {
            Image(systemName: symbol).foregroundStyle(color).frame(width: 26)
            Text(text).font(.subheadline.weight(.semibold))
            Spacer()
            Image(systemName: "checkmark").font(.caption.weight(.black)).foregroundStyle(AppTheme.cyan)
        }
    }
}
