import SpriteKit
import UIKit

@MainActor
final class BattleScene: SKScene {
    var onHUDChange: ((BattleHUD) -> Void)?
    var onFinished: ((RunResult) -> Void)?

    private let configuration: BattleConfiguration
    private let world = SKNode()
    private let squad = SKNode()
    private let playfield = SKShapeNode()
    private var soldiers: [SKNode] = []
    private var squadHealth: Double
    private var damageMultiplier = 1.0
    private var elapsed: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var nextWaveTime: TimeInterval = 2.6
    private var nextGateTime: TimeInterval = 4.8
    private var lastShotTime: TimeInterval = 0
    private var defeated = 0
    private var score = 0
    private var fortress: SKNode?
    private var fortressHealth: Double = 0
    private var didFinish = false
    private var didShowGuide = false
    private let runDuration: TimeInterval = 30

    init(size: CGSize, configuration: BattleConfiguration) {
        self.configuration = configuration
        self.squadHealth = Double(configuration.startingSquad)
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = UIColor(red: 0.035, green: 0.065, blue: 0.14, alpha: 1)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func didMove(to view: SKView) {
        anchorPoint = .zero
        addChild(playfield)
        addChild(world)
        addChild(squad)
        rebuildField()
        squad.position = CGPoint(x: size.width / 2, y: max(150, size.height * 0.19))
        rebuildSquad()
        showGuide()
        publishHUD(status: "DRAG TO STEER")
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard view != nil else { return }
        rebuildField()
        squad.position.y = max(150, size.height * 0.19)
        squad.position.x = min(max(52, squad.position.x), size.width - 52)
    }

    private func rebuildField() {
        let rect = CGRect(x: 18, y: -20, width: max(10, size.width - 36), height: size.height + 40)
        playfield.path = CGPath(roundedRect: rect, cornerWidth: 26, cornerHeight: 26, transform: nil)
        playfield.fillColor = UIColor(red: 0.10, green: 0.18, blue: 0.23, alpha: 1)
        playfield.strokeColor = UIColor.white.withAlphaComponent(0.08)
        playfield.lineWidth = 2
        playfield.zPosition = -20
        addRoadMarks()
    }

    private func addRoadMarks() {
        world.children.filter { $0.name == "roadMark" }.forEach { $0.removeFromParent() }
        for row in 0..<12 {
            let mark = SKShapeNode(rectOf: CGSize(width: 5, height: 34), cornerRadius: 2)
            mark.name = "roadMark"
            mark.fillColor = UIColor.white.withAlphaComponent(0.07)
            mark.strokeColor = .clear
            mark.position = CGPoint(x: size.width / 2, y: CGFloat(row) * 100)
            mark.zPosition = -10
            world.addChild(mark)
        }
    }

    private func showGuide() {
        guard !didShowGuide else { return }
        didShowGuide = true
        let guide = SKLabelNode(fontNamed: "AvenirNext-Bold")
        guide.text = "CHOOSE YOUR LINE"
        guide.fontSize = 15
        guide.fontColor = UIColor.white.withAlphaComponent(0.72)
        guide.position = CGPoint(x: size.width / 2, y: squad.position.y - 90)
        guide.run(.sequence([.wait(forDuration: 2), .fadeOut(withDuration: 0.6), .removeFromParent()]))
        addChild(guide)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { moveSquad(with: touches) }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { moveSquad(with: touches) }

    private func moveSquad(with touches: Set<UITouch>) {
        guard let touch = touches.first, !didFinish else { return }
        let x = min(max(48, touch.location(in: self).x), size.width - 48)
        squad.run(.moveTo(x: x, duration: 0.08))
    }

    override func update(_ currentTime: TimeInterval) {
        guard !didFinish else { return }
        let delta = lastUpdateTime == 0 ? 0 : min(currentTime - lastUpdateTime, 1.0 / 20.0)
        lastUpdateTime = currentTime
        guard delta > 0 else { return }
        elapsed += delta

        scrollWorld(by: CGFloat(115 * delta))
        if elapsed >= nextWaveTime && elapsed < runDuration - 4 {
            spawnWave()
            nextWaveTime += max(2.2, 3.5 - Double(configuration.level) * 0.08)
        }
        if elapsed >= nextGateTime && elapsed < runDuration - 6 {
            spawnGatePair()
            nextGateTime += 6.2
        }
        if elapsed >= runDuration - 4, fortress == nil { spawnFortress() }

        resolveGates()
        resolveCombat(delta: delta)
        cleanupOffscreen()

        if squadHealth <= 0 { finish(win: false) }
        publishHUD()
    }

    private func scrollWorld(by amount: CGFloat) {
        for node in world.children where node.name != "roadMark" {
            if node.name == "fortress", node.position.y <= size.height - 155 { continue }
            node.position.y -= amount
        }
        for mark in world.children where mark.name == "roadMark" {
            mark.position.y -= amount * 0.55
            if mark.position.y < -40 { mark.position.y += 1_200 }
        }
    }

    private func spawnWave() {
        let count = min(8, 2 + Int(elapsed / 7) + configuration.level / 3)
        let centerX = CGFloat.random(in: 72...(size.width - 72))
        for index in 0..<count {
            let enemy = makeSoldier(color: UIColor(red: 0.91, green: 0.20, blue: 0.24, alpha: 1), enemy: true)
            enemy.name = "enemy"
            let health = (9.0 + Double(count) * 1.2) * configuration.enemyHealthMultiplier
            enemy.userData = ["health": health, "maxHealth": health]
            let column = index % 3
            let row = index / 3
            enemy.position = CGPoint(
                x: min(max(42, centerX + CGFloat(column - 1) * 32), size.width - 42),
                y: size.height + 50 + CGFloat(row) * 34
            )
            world.addChild(enemy)
        }
    }

    private func spawnGatePair() {
        let pair = SKNode()
        pair.name = "gatePair"
        pair.position = CGPoint(x: size.width / 2, y: size.height + 90)
        pair.userData = ["used": false]

        let recruitCount = 3 + Int(elapsed / 10)
        let left = makeGate(reward: .recruits(recruitCount), color: UIColor(red: 0.08, green: 0.66, blue: 0.92, alpha: 1))
        left.position.x = -(size.width - 54) / 4
        left.userData = ["kind": "recruits", "value": recruitCount]
        pair.addChild(left)

        let multiplier = elapsed > 16 ? 1.5 : 1.3
        let right = makeGate(reward: .damage(multiplier), color: UIColor(red: 0.96, green: 0.61, blue: 0.12, alpha: 1))
        right.position.x = (size.width - 54) / 4
        right.userData = ["kind": "damage", "value": multiplier]
        pair.addChild(right)
        world.addChild(pair)
    }

    private func makeGate(reward: GateReward, color: UIColor) -> SKNode {
        let gate = SKShapeNode(rectOf: CGSize(width: (size.width - 62) / 2, height: 82), cornerRadius: 15)
        gate.fillColor = color.withAlphaComponent(0.9)
        gate.strokeColor = color.lighter()
        gate.lineWidth = 3

        let main = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        main.text = reward.label
        main.fontSize = 31
        main.verticalAlignmentMode = .center
        main.position.y = 8
        gate.addChild(main)

        let sub = SKLabelNode(fontNamed: "AvenirNext-Bold")
        sub.text = reward.subtitle
        sub.fontSize = 9
        sub.fontColor = UIColor.white.withAlphaComponent(0.82)
        sub.position.y = -25
        gate.addChild(sub)
        return gate
    }

    private func resolveGates() {
        for pair in world.children where pair.name == "gatePair" {
            guard abs(pair.position.y - squad.position.y) < 18,
                  pair.userData?["used"] as? Bool == false else { continue }
            pair.userData?["used"] = true
            let chosen = squad.position.x < size.width / 2 ? pair.children[0] : pair.children[1]
            let kind = chosen.userData?["kind"] as? String
            if kind == "recruits", let count = chosen.userData?["value"] as? Int {
                squadHealth += Double(count)
                flashStatus("+\(count) REINFORCEMENTS")
                impact(.medium)
                rebuildSquad()
            } else if let multiplier = chosen.userData?["value"] as? Double {
                damageMultiplier *= multiplier
                flashStatus("FIREPOWER ×\(String(format: "%.1f", multiplier))")
                impact(.rigid)
            }
            chosen.run(.sequence([.scale(to: 1.14, duration: 0.08), .fadeOut(withDuration: 0.22)]))
            for other in pair.children where other !== chosen { other.alpha = 0.15 }
        }
    }

    private func spawnFortress() {
        let node = SKNode()
        node.name = "fortress"
        node.position = CGPoint(x: size.width / 2, y: size.height + 155)
        fortressHealth = configuration.fortressHealth
        let wall = SKShapeNode(rectOf: CGSize(width: size.width - 70, height: 130), cornerRadius: 18)
        wall.fillColor = UIColor(red: 0.63, green: 0.17, blue: 0.18, alpha: 1)
        wall.strokeColor = UIColor(red: 1, green: 0.36, blue: 0.27, alpha: 1)
        wall.lineWidth = 5
        node.addChild(wall)
        for offset in stride(from: -size.width / 2 + 68, through: size.width / 2 - 68, by: 42) {
            let merlon = SKShapeNode(rectOf: CGSize(width: 25, height: 35), cornerRadius: 5)
            merlon.fillColor = wall.fillColor
            merlon.strokeColor = wall.strokeColor
            merlon.lineWidth = 2
            merlon.position = CGPoint(x: offset, y: 72)
            node.addChild(merlon)
        }
        let emblem = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        emblem.text = "FORTRESS"
        emblem.fontSize = 18
        emblem.verticalAlignmentMode = .center
        node.addChild(emblem)
        world.addChild(node)
        fortress = node
        flashStatus("BREAK THE FORTRESS")
        notify(.warning)
    }

    private func resolveCombat(delta: TimeInterval) {
        let enemies = world.children.filter { $0.name == "enemy" }
        let liveTarget = ([fortress].compactMap { $0 } + enemies)
            .filter { $0.position.y > squad.position.y + 45 && $0.position.y < size.height + 20 }
            .min { $0.position.y < $1.position.y }

        if let target = liveTarget {
            let squadCount = max(0, Int(ceil(squadHealth)))
            let dps = configuration.baseDamagePerSecond * damageMultiplier + Double(squadCount) * 0.72
            if target.name == "fortress" {
                fortressHealth -= dps * delta
                if fortressHealth <= 0 {
                    target.run(.sequence([.group([.scale(to: 1.18, duration: 0.18), .fadeOut(withDuration: 0.3)]), .removeFromParent()]))
                    finish(win: true)
                }
            } else if let health = target.userData?["health"] as? Double {
                let updated = health - dps * delta
                target.userData?["health"] = updated
                target.alpha = 0.72 + CGFloat(max(0, updated / (target.userData?["maxHealth"] as? Double ?? 1))) * 0.28
                if updated <= 0 {
                    defeated += 1
                    score += 100
                    target.name = "defeated"
                    target.run(.sequence([.group([.scale(to: 0.1, duration: 0.18), .fadeOut(withDuration: 0.18)]), .removeFromParent()]))
                }
            }
            if elapsed - lastShotTime > 0.16 {
                fireTracer(at: target.position)
                lastShotTime = elapsed
            }
        }

        let attackers = enemies.filter {
            abs($0.position.y - squad.position.y) < 58 && abs($0.position.x - squad.position.x) < 105
        }
        if !attackers.isEmpty {
            squadHealth -= Double(attackers.count) * delta * (1.1 - configuration.damageResistance)
            let priorCount = soldiers.count
            if Int(ceil(squadHealth)) != priorCount {
                rebuildSquad()
                impact(.light)
            }
        }
    }

    private func fireTracer(at target: CGPoint) {
        guard let origin = soldiers.randomElement()?.convert(CGPoint.zero, to: self) else { return }
        let path = CGMutablePath()
        path.move(to: origin)
        path.addLine(to: target)
        let tracer = SKShapeNode(path: path)
        tracer.strokeColor = UIColor(red: 1, green: 0.76, blue: 0.18, alpha: 0.8)
        tracer.lineWidth = 2
        tracer.glowWidth = 3
        tracer.zPosition = 20
        tracer.run(.sequence([.fadeOut(withDuration: 0.08), .removeFromParent()]))
        addChild(tracer)
    }

    private func cleanupOffscreen() {
        for node in world.children where node.name != "roadMark" && node.position.y < -120 {
            node.removeFromParent()
        }
    }

    private func rebuildSquad() {
        soldiers.forEach { $0.removeFromParent() }
        soldiers.removeAll()
        let count = max(0, min(25, Int(ceil(squadHealth))))
        let color: UIColor = switch configuration.skin {
        case .cobalt: UIColor(red: 0.10, green: 0.45, blue: 0.96, alpha: 1)
        case .ember: UIColor(red: 0.97, green: 0.39, blue: 0.15, alpha: 1)
        case .ivory: UIColor(red: 0.92, green: 0.90, blue: 0.78, alpha: 1)
        }
        for index in 0..<count {
            let soldier = makeSoldier(color: color, enemy: false)
            let row = Int(sqrt(Double(index)))
            let rowStart = row * row
            let positionInRow = index - rowStart
            let itemsInRow = row * 2 + 1
            soldier.position = CGPoint(
                x: CGFloat(positionInRow) * 24 - CGFloat(itemsInRow - 1) * 12,
                y: CGFloat(row) * -26
            )
            squad.addChild(soldier)
            soldiers.append(soldier)
        }
    }

    private func makeSoldier(color: UIColor, enemy: Bool) -> SKNode {
        let node = SKNode()
        let body = SKShapeNode(rect: CGRect(x: -9, y: -13, width: 18, height: 24), cornerRadius: 6)
        body.fillColor = color
        body.strokeColor = color.lighter()
        body.lineWidth = 1.5
        node.addChild(body)
        let helmet = SKShapeNode(circleOfRadius: 8)
        helmet.position.y = 11
        helmet.fillColor = color.lighter()
        helmet.strokeColor = UIColor.white.withAlphaComponent(0.4)
        helmet.lineWidth = 1
        node.addChild(helmet)
        let weapon = SKShapeNode(rectOf: CGSize(width: 3, height: 18), cornerRadius: 1.5)
        weapon.position = CGPoint(x: enemy ? -10 : 10, y: 4)
        weapon.zRotation = enemy ? .pi / 5 : -.pi / 5
        weapon.fillColor = .darkGray
        weapon.strokeColor = .clear
        node.addChild(weapon)
        node.zPosition = enemy ? 5 : 10
        return node
    }

    private func flashStatus(_ text: String) {
        publishHUD(status: text)
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = 18
        label.fontColor = .white
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.58)
        label.zPosition = 50
        label.run(.sequence([.moveBy(x: 0, y: 16, duration: 0.6), .fadeOut(withDuration: 0.3), .removeFromParent()]))
        addChild(label)
    }

    private func publishHUD(status: String? = nil) {
        let bossFraction = fortress == nil ? nil : max(0, fortressHealth / configuration.fortressHealth)
        onHUDChange?(BattleHUD(
            squadCount: max(0, Int(ceil(squadHealth))),
            score: score,
            progress: min(1, elapsed / runDuration),
            bossHealthFraction: bossFraction,
            statusText: status
        ))
    }

    private func finish(win: Bool) {
        guard !didFinish else { return }
        didFinish = true
        isPaused = true
        let remaining = max(0, Int(ceil(squadHealth)))
        let finalScore = GameRules.score(didWin: win, defeated: defeated, remaining: remaining)
        let reward = GameRules.reward(didWin: win, defeated: defeated, remaining: remaining)
        let result = RunResult(didWin: win, score: finalScore, coinsEarned: reward, enemiesDefeated: defeated, squadRemaining: remaining)
        notify(win ? .success : .error)
        onFinished?(result)
    }

    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard configuration.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard configuration.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

private extension UIColor {
    func lighter() -> UIColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return UIColor(red: min(1, red + 0.2), green: min(1, green + 0.2), blue: min(1, blue + 0.2), alpha: alpha)
    }
}
