import SwiftUI

struct ArmoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PlayerProgress.self) private var progress
    @Environment(PurchaseService.self) private var purchases
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Text("Permanent field upgrades")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                        Label("\(progress.coins)", systemImage: "hexagon.fill")
                            .font(.headline.weight(.black)).foregroundStyle(AppTheme.gold)
                    }
                    ForEach(UpgradeType.allCases) { type in
                        upgradeCard(type)
                    }
                    skinSection
                }
                .padding(20)
            }
            .background(AppTheme.navy.ignoresSafeArea())
            .navigationTitle("Armory")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private func upgradeCard(_ type: UpgradeType) -> some View {
        let cost = progress.upgradeCost(for: type)
        let canBuy = progress.coins >= cost
        return HStack(spacing: 15) {
            Image(systemName: type.symbol)
                .font(.title2).foregroundStyle(AppTheme.cyan)
                .frame(width: 48, height: 48)
                .background(AppTheme.cyan.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(type.title).font(.headline.weight(.bold))
                    Text("LV \(progress.level(for: type))").font(.caption2.weight(.black)).foregroundStyle(AppTheme.cyan)
                }
                Text(type.subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                if progress.buy(type) { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
            } label: {
                Label("\(cost)", systemImage: "hexagon.fill")
                    .font(.subheadline.weight(.black))
                    .padding(.horizontal, 11).padding(.vertical, 9)
                    .background(canBuy ? AppTheme.cobalt : .white.opacity(0.07), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!canBuy)
        }
        .gamePanel()
    }

    private var skinSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("SQUAD COLORS").font(.caption.weight(.black)).foregroundStyle(.secondary)
                Spacer()
                if !purchases.isPremium {
                    Button("Unlock") { showPaywall = true }.font(.caption.weight(.bold)).foregroundStyle(AppTheme.gold)
                }
            }
            HStack(spacing: 12) {
                skinButton(.cobalt, color: AppTheme.cobalt, locked: false)
                skinButton(.ember, color: .orange, locked: !purchases.isPremium)
                skinButton(.ivory, color: AppTheme.ivory, locked: !purchases.isPremium)
            }
        }
        .gamePanel()
    }

    private func skinButton(_ skin: SquadSkin, color: Color, locked: Bool) -> some View {
        Button {
            if locked { showPaywall = true } else { progress.selectedSkin = skin }
        } label: {
            VStack(spacing: 7) {
                ZStack {
                    Circle().fill(color).frame(width: 42, height: 42)
                    if locked { Image(systemName: "lock.fill").foregroundStyle(.black.opacity(0.6)) }
                    if progress.selectedSkin == skin { Circle().stroke(.white, lineWidth: 3).frame(width: 50, height: 50) }
                }
                Text(skin.title).font(.caption2.weight(.bold)).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
