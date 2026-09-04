import SwiftUI

struct HomeView: View {
    @Environment(PlayerProgress.self) private var progress
    @Environment(PurchaseService.self) private var purchases
    @State private var showGame = false
    @State private var showArmory = false
    @State private var showPaywall = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppTheme.navy, Color(red: 0.025, green: 0.14, blue: 0.20)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            decorativeField
            ScrollView {
                VStack(spacing: 22) {
                    topBar
                    hero
                    primaryAction
                    stats
                    actionGrid
                    if !purchases.isPremium { commanderBanner }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .foregroundStyle(.white)
        .fullScreenCover(isPresented: $showGame) { GameView() }
        .sheet(isPresented: $showArmory) { ArmoryView() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("BASTION").font(.system(size: 13, weight: .black, design: .rounded)).foregroundStyle(AppTheme.cyan)
                HStack(spacing: 7) {
                    Text("RUSH").font(.system(size: 28, weight: .black, design: .rounded))
                    if purchases.isPremium {
                        Image(systemName: "crown.fill").foregroundStyle(AppTheme.gold)
                    }
                }
            }
            Spacer()
            Label("\(progress.coins)", systemImage: "hexagon.fill")
                .font(.headline.weight(.black))
                .foregroundStyle(AppTheme.gold)
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(.black.opacity(0.28), in: Capsule())
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill").font(.title3).frame(width: 42, height: 42)
                    .background(.white.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    private var hero: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(AppTheme.cobalt.opacity(0.16)).frame(width: 225, height: 225)
                Circle().stroke(AppTheme.cyan.opacity(0.18), lineWidth: 1).frame(width: 190, height: 190)
                squadFormation
            }
            VStack(spacing: 4) {
                Text(progress.wins == 0 ? "FIRST DEPLOYMENT" : "SECTOR \(progress.wins + 1)")
                    .font(.caption.weight(.black)).foregroundStyle(AppTheme.cyan).tracking(1.8)
                Text(progress.wins == 0 ? "Hold the line." : "The enemy adapted. So did you.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    private var squadFormation: some View {
        ZStack {
            ForEach(0..<9, id: \.self) { index in
                let row = index / 3
                let column = index % 3
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 39, weight: .bold))
                    .foregroundStyle(index == 1 ? AppTheme.gold : AppTheme.cobalt)
                    .shadow(color: .black.opacity(0.45), radius: 3, y: 5)
                    .offset(x: CGFloat(column - 1) * 47, y: CGFloat(row - 1) * 43)
            }
        }
        .rotationEffect(.degrees(-4))
    }

    private var primaryAction: some View {
        Button {
            showGame = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill").font(.title2)
                VStack(alignment: .leading, spacing: 1) {
                    Text("START RUN").font(.title3.weight(.black))
                    Text("One thumb · about 35 seconds").font(.caption).opacity(0.72)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.headline.weight(.black))
            }
            .padding(18)
            .background(
                LinearGradient(colors: [AppTheme.cobalt, Color(red: 0.06, green: 0.63, blue: 0.82)], startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 21, style: .continuous)
            )
            .shadow(color: AppTheme.cobalt.opacity(0.28), radius: 18, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var stats: some View {
        HStack(spacing: 10) {
            statCard("WINS", "\(progress.wins)", "flag.checkered")
            statCard("BEST", "\(progress.bestScore)", "trophy.fill")
            statCard("SQUAD", "\(progress.startingSquad)", "person.3.fill")
        }
    }

    private func statCard(_ title: String, _ value: String, _ symbol: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: symbol).foregroundStyle(AppTheme.cyan)
            Text(value).font(.headline.weight(.black)).minimumScaleFactor(0.7)
            Text(title).font(.system(size: 9, weight: .black)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppTheme.panel.opacity(0.82), in: RoundedRectangle(cornerRadius: 17))
    }

    private var actionGrid: some View {
        HStack(spacing: 12) {
            actionButton("Armory", "Upgrade squad", "hammer.fill", AppTheme.gold) { showArmory = true }
            actionButton("Intel", "How to play", "map.fill", AppTheme.cyan) { showSettings = true }
        }
    }

    private func actionButton(_ title: String, _ subtitle: String, _ symbol: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: symbol).font(.title3).foregroundStyle(color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.bold))
                    Text(subtitle).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(AppTheme.panel.opacity(0.82), in: RoundedRectangle(cornerRadius: 17))
        }
        .buttonStyle(.plain)
    }

    private var commanderBanner: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 13) {
                Image(systemName: "crown.fill").font(.title2).foregroundStyle(AppTheme.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("COMMANDER PACK").font(.subheadline.weight(.black))
                    Text("2 exclusive colors + supporter badge").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(16)
            .background(AppTheme.gold.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
            .overlay { RoundedRectangle(cornerRadius: 18).stroke(AppTheme.gold.opacity(0.25)) }
        }
        .buttonStyle(.plain)
    }

    private var decorativeField: some View {
        GeometryReader { proxy in
            ForEach(0..<12, id: \.self) { index in
                Circle()
                    .fill((index.isMultiple(of: 3) ? AppTheme.coral : AppTheme.cyan).opacity(0.07))
                    .frame(width: CGFloat(8 + (index % 4) * 5))
                    .position(x: CGFloat((index * 79) % max(1, Int(proxy.size.width))), y: CGFloat(90 + index * 71))
            }
        }
        .allowsHitTesting(false)
    }
}
