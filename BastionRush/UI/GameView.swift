import SwiftUI
import SpriteKit

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PlayerProgress.self) private var progress
    @State private var scene: BattleScene?
    @State private var hud = BattleHUD(squadCount: 0, score: 0, progress: 0, bossHealthFraction: nil, statusText: nil)
    @State private var result: RunResult?
    @State private var didRecordResult = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AppTheme.navy.ignoresSafeArea()
                if let scene {
                    SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                        .ignoresSafeArea()
                }
                VStack(spacing: 10) {
                    gameHUD
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)

                if let result {
                    Color.black.opacity(0.62).ignoresSafeArea()
                    ResultCard(result: result, onReplay: restart, onHome: { dismiss() })
                        .padding(24)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .onAppear {
                if scene == nil { createScene(size: proxy.size) }
            }
            .onChange(of: proxy.size) { _, newSize in
                scene?.size = newSize
            }
        }
        .navigationBarBackButtonHidden()
        .statusBarHidden()
    }

    private var gameHUD: some View {
        VStack(spacing: 9) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "pause.fill")
                        .frame(width: 42, height: 42)
                        .background(.black.opacity(0.36), in: Circle())
                }
                Spacer()
                Label("\(hud.squadCount)", systemImage: "person.3.fill")
                    .font(.headline.weight(.heavy))
                    .contentTransition(.numericText())
                Spacer()
                Text("\(hud.score)")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .frame(minWidth: 54, alignment: .trailing)
            }
            ProgressView(value: hud.bossHealthFraction ?? hud.progress)
                .tint(hud.bossHealthFraction == nil ? AppTheme.cyan : AppTheme.coral)
                .background(.white.opacity(0.14))
                .clipShape(Capsule())
            if let boss = hud.bossHealthFraction {
                Text("FORTRESS  \(Int(boss * 100))%")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(AppTheme.coral)
            }
        }
        .foregroundStyle(.white)
    }

    private func createScene(size: CGSize) {
        let config = BattleConfiguration(
            startingSquad: progress.startingSquad,
            baseDamagePerSecond: progress.damagePerSecond,
            damageResistance: progress.damageResistance,
            level: progress.wins,
            skin: progress.selectedSkin,
            hapticsEnabled: UserDefaults.standard.object(forKey: "hapticsEnabled") == nil
                ? true
                : UserDefaults.standard.bool(forKey: "hapticsEnabled")
        )
        let newScene = BattleScene(size: size, configuration: config)
        newScene.onHUDChange = { update in hud = update }
        newScene.onFinished = { finished in
            guard !didRecordResult else { return }
            didRecordResult = true
            progress.record(finished)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { result = finished }
        }
        scene = newScene
    }

    private func restart() {
        result = nil
        didRecordResult = false
        scene = nil
        createScene(size: UIScreen.main.bounds.size)
    }
}

private struct ResultCard: View {
    let result: RunResult
    let onReplay: () -> Void
    let onHome: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: result.didWin ? "crown.fill" : "shield.slash.fill")
                .font(.system(size: 46, weight: .black))
                .foregroundStyle(result.didWin ? AppTheme.gold : AppTheme.coral)
            VStack(spacing: 5) {
                Text(result.didWin ? "FORTRESS BROKEN" : "LINE LOST")
                    .font(.title2.weight(.black))
                Text(result.didWin ? "Your squad held the line." : "Upgrade, regroup, and push again.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 22) {
                stat("SCORE", "\(result.score)")
                stat("DEFEATED", "\(result.enemiesDefeated)")
                stat("COINS", "+\(result.coinsEarned)")
            }
            Button(action: onReplay) {
                Label("Run It Back", systemImage: "arrow.clockwise")
                    .font(.headline.weight(.heavy))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .background(AppTheme.cobalt, in: RoundedRectangle(cornerRadius: 16))
            Button("Back to Base", action: onHome)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .gamePanel()
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.title3.weight(.black)).foregroundStyle(label == "COINS" ? AppTheme.gold : .white)
            Text(label).font(.system(size: 9, weight: .black)).foregroundStyle(.secondary)
        }
    }
}
