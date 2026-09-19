import SpriteKit
import UIKit

@MainActor
final class BattleScene: SKScene {
    #if DEBUG
    private static var hasUsedDebugInstantDefeat = false
    #endif
    var onHUDChange: ((BattleHUD) -> Void)?
    var onFinished: ((RunResult) -> Void)?

    private let configuration: BattleConfiguration
    private let world = SKNode()
    private let squad = SKNode()
    private let playfield = SKShapeNode()
    private let fieldBackdrop = SKSpriteNode(imageNamed: "Battlefield")
    private let aimGuide = SKShapeNode()
    private var soldiers: [SKNode] = []
    private var squadHealth: Double
    private var damageMultiplier = 1.0
    private var elapsed: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var nextWaveTime: TimeInterval = 2.6
    private var nextGateTime: TimeInterval = 0.25
    private var nextHazardTime: TimeInterval = 7.4
    private var lastWaveSpawnTime: TimeInterval = -100
    private var gateClearUntil: TimeInterval = 0
    private var lastShotTime: TimeInterval = 0
    private var lastFortressShotTime: TimeInterval = 0
    private var lastRallyTime: TimeInterval = -10
    private var defeated = 0
    private var score = 0
    private var killCoins = 0
    private var brutesSpawned = 0
    private var gatesSpawned = 0
    private var announcedEnemyKinds: Set<EnemyKind> = []
    private var fortress: SKNode?
    private var fortressHealth: Double = 0
    private var didFinish = false
    private var didShowGuide = false
    private var threatPresent = false
    private var targetAligned = false
    private let runDuration: TimeInterval = 32
    private let rallyDuration: TimeInterval = 3.2
    private let rallyCooldown: TimeInterval = 10

    private var isRallying: Bool { elapsed - lastRallyTime < rallyDuration }
    private var fireLaneWidth: CGFloat { isRallying ? 160 : CGFloat(configuration.baseFireLaneWidth) }

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
        addChild(fieldBackdrop)
        addChild(playfield)
        addChild(world)
        addChild(squad)
        rebuildField()
        squad.position = CGPoint(x: size.width / 2, y: max(150, size.height * 0.19))
        buildAimGuide()
        rebuildSquad()
        showGuide()
        publishHUD(status: "DRAG TO STEER")
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard view != nil else { return }
        rebuildField()
        squad.position.y = max(150, size.height * 0.19)
        squad.position.x = min(max(52, squad.position.x), size.width - 52)
        buildAimGuide()
    }

    private func rebuildField() {
        fieldBackdrop.position = CGPoint(x: size.width / 2, y: size.height / 2)
        fieldBackdrop.size = size
        fieldBackdrop.zPosition = -30
        fieldBackdrop.alpha = 0.92
        let rect = CGRect(x: 18, y: -20, width: max(10, size.width - 36), height: size.height + 40)
        playfield.path = CGPath(roundedRect: rect, cornerWidth: 26, cornerHeight: 26, transform: nil)
        playfield.fillColor = UIColor(red: 0.02, green: 0.08, blue: 0.12, alpha: 0.13)
        playfield.strokeColor = UIColor.white.withAlphaComponent(0.13)
        playfield.lineWidth = 2
        playfield.zPosition = -20
        addRoadMarks()
        addFieldDetails()
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

    private func addFieldDetails() {
        children.filter { $0.name == "fieldDetail" }.forEach { $0.removeFromParent() }
        for side in [-1.0, 1.0] {
            let edge = SKShapeNode(rectOf: CGSize(width: 8, height: size.height + 20), cornerRadius: 4)
            edge.name = "fieldDetail"
            edge.fillColor = UIColor(red: 0.06, green: 0.42, blue: 0.52, alpha: 0.22)
            edge.strokeColor = UIColor(red: 0.12, green: 0.76, blue: 0.92, alpha: 0.18)
            edge.position = CGPoint(x: side < 0 ? 23 : size.width - 23, y: size.height / 2)
            edge.zPosition = -18
            addChild(edge)
        }
    }

    private func buildAimGuide() {
        aimGuide.removeFromParent()
        let halfWidth = fireLaneWidth / 2
        let length = max(400, size.height - squad.position.y)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -22, y: 20))
        path.addLine(to: CGPoint(x: -halfWidth, y: length))
        path.addLine(to: CGPoint(x: halfWidth, y: length))
        path.addLine(to: CGPoint(x: 22, y: 20))
        path.closeSubpath()
        aimGuide.path = path
        aimGuide.fillColor = UIColor(red: 0.13, green: 0.71, blue: 0.93, alpha: isRallying ? 0.12 : 0.045)
        aimGuide.strokeColor = UIColor(red: 0.20, green: 0.80, blue: 1, alpha: isRallying ? 0.55 : 0.15)
        aimGuide.lineWidth = isRallying ? 2.5 : 1
        aimGuide.zPosition = -2
        squad.addChild(aimGuide)
    }

    func activateRally() {
        guard !didFinish, elapsed - lastRallyTime >= rallyCooldown else { return }
        lastRallyTime = elapsed
        buildAimGuide()
        flashStatus("RALLY — WIDE FIRE LANE")
        impact(.heavy)
        squad.run(.sequence([.scale(to: 1.08, duration: 0.12), .scale(to: 1, duration: 0.2)]))
    }

    private func showGuide() {
        guard !didShowGuide else { return }
        didShowGuide = true
        let guide = SKLabelNode(fontNamed: "AvenirNext-Bold")
        guide.text = "ALIGN TO FIRE • DODGE RED SHOTS"
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

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-instantDefeat"),
           !Self.hasUsedDebugInstantDefeat,
           elapsed > 0.6 {
            Self.hasUsedDebugInstantDefeat = true
            finish(win: false)
            return
        }
        #endif

        scrollWorld(by: CGFloat(115 * delta))
        if elapsed >= nextGateTime && elapsed < runDuration - 6 {
            if elapsed - lastWaveSpawnTime >= 3.15 {
                spawnGatePair()
                gateClearUntil = elapsed + 3.15
                nextWaveTime = max(nextWaveTime, gateClearUntil)
                nextHazardTime = max(nextHazardTime, gateClearUntil)
                nextGateTime = elapsed + 7.2
            } else {
                nextGateTime = lastWaveSpawnTime + 3.15
            }
        }
        if elapsed >= nextWaveTime && elapsed >= gateClearUntil && elapsed < runDuration - 4 {
            spawnWave()
            lastWaveSpawnTime = elapsed
            nextWaveTime = elapsed + configuration.waveInterval
        }
        if elapsed >= nextHazardTime && elapsed >= gateClearUntil && elapsed < runDuration - 5 {
            spawnHazard()
            nextHazardTime = elapsed + 6.4
        }
        if elapsed >= runDuration - 4, fortress == nil { spawnFortress() }

        resolveGates()
        resolveCombat(delta: delta)
        updateEnemyProjectiles(delta: delta)
        resolveHazards()
        cleanupOffscreen()

        if !isRallying, elapsed - lastRallyTime < rallyDuration + 0.08 { buildAimGuide() }

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
        let count = min(
            configuration.maxWaveCount,
            configuration.baseWaveCount + Int(elapsed / (configuration.isRecruitRun ? 9 : 6)) + configuration.level / 3
        )
        let roster = GameRules.defenderRoster(
            level: configuration.level,
            elapsed: elapsed,
            count: count,
            brutesSpawned: brutesSpawned
        )
        announceNewEnemyType(in: roster)
        if roster.contains(.brute) { brutesSpawned += 1 }
        let centerX = CGFloat.random(in: 72...(size.width - 72))
        for (index, kind) in roster.enumerated() {
            let enemy = makeEnemy(kind: kind)
            enemy.name = "enemy"
            let health = (kind.baseHealth + Double(count) * 1.1) * configuration.enemyHealthMultiplier
            enemy.userData = [
                "health": health,
                "maxHealth": health,
                "nextShot": elapsed + Double.random(in: 0.8...2.0),
                "canShoot": kind.projectileMultiplier > 0 && index.isMultiple(of: configuration.shooterStride),
                "kind": kind.rawValue,
                "coinReward": kind.coinReward,
                "contactMultiplier": kind.contactMultiplier,
                "projectileMultiplier": kind.projectileMultiplier
            ]
            let healthBar = makeHealthBar(width: kind == .brute ? 36 : (kind == .shield ? 27 : 23))
            if kind == .brute { healthBar.position.y = 52 }
            enemy.addChild(healthBar)
            let column = index % 3
            let row = index / 3
            if kind == .brute {
                enemy.position = CGPoint(x: centerX, y: size.height + 95 + CGFloat(row) * 40)
            } else {
                enemy.position = CGPoint(
                    x: min(max(42, centerX + CGFloat(column - 1) * 32), size.width - 42),
                    y: size.height + 50 + CGFloat(row) * 40
                )
            }
            world.addChild(enemy)
        }
    }

    private func spawnHazard() {
        let hazard = SKNode()
        hazard.name = "hazard"
        hazard.position = CGPoint(x: CGFloat.random(in: 70...(size.width - 70)), y: size.height + 70)

        let shadow = SKShapeNode(ellipseOf: CGSize(width: 76, height: 25))
        shadow.fillColor = UIColor.black.withAlphaComponent(0.3)
        shadow.strokeColor = .clear
        shadow.position.y = -8
        hazard.addChild(shadow)

        for index in 0..<3 {
            let mine = SKShapeNode(circleOfRadius: 12)
            mine.fillColor = UIColor(red: 0.43, green: 0.11, blue: 0.12, alpha: 1)
            mine.strokeColor = UIColor(red: 1, green: 0.32, blue: 0.20, alpha: 1)
            mine.lineWidth = 2
            mine.position.x = CGFloat(index - 1) * 24
            let core = SKShapeNode(circleOfRadius: 4)
            core.fillColor = UIColor(red: 1, green: 0.64, blue: 0.10, alpha: 1)
            core.strokeColor = .clear
            core.run(.repeatForever(.sequence([.fadeAlpha(to: 0.25, duration: 0.35), .fadeAlpha(to: 1, duration: 0.35)])))
            mine.addChild(core)
            hazard.addChild(mine)
        }

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "DANGER"
        label.fontSize = 9
        label.fontColor = UIColor(red: 1, green: 0.48, blue: 0.20, alpha: 1)
        label.position.y = 24
        hazard.addChild(label)
        world.addChild(hazard)
    }

    private func spawnGatePair() {
        let isOpeningGate = gatesSpawned == 0
        gatesSpawned += 1
        let pair = SKNode()
        pair.name = "gatePair"
        pair.position = CGPoint(
            x: size.width / 2,
            y: isOpeningGate ? size.height * 0.72 : size.height + 90
        )
        pair.userData = ["used": false]

        if isOpeningGate {
            let instruction = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            instruction.text = "CHOOSE YOUR BOOST"
            instruction.fontSize = 14
            instruction.fontColor = UIColor.white.withAlphaComponent(0.9)
            instruction.position.y = 68
            pair.addChild(instruction)
        }

        let recruitCount = 4 + Int(elapsed / 10)
        let left = makeGate(reward: .recruits(recruitCount), color: UIColor(red: 0.08, green: 0.66, blue: 0.92, alpha: 1))
        left.name = "leftGate"
        left.position.x = -(size.width - 54) / 4
        left.userData = ["kind": "recruits", "value": recruitCount]
        pair.addChild(left)

        let multiplier = elapsed > 16 ? 1.5 : 1.3
        let right = makeGate(reward: .damage(multiplier), color: UIColor(red: 0.96, green: 0.61, blue: 0.12, alpha: 1))
        right.name = "rightGate"
        right.position.x = (size.width - 54) / 4
        right.userData = ["kind": "damage", "value": multiplier]
        pair.addChild(right)
        world.addChild(pair)
    }

    private func makeGate(reward: GateReward, color: UIColor) -> SKNode {
        let container = SKNode()
        let shadow = SKShapeNode(rectOf: CGSize(width: (size.width - 62) / 2, height: 82), cornerRadius: 15)
        shadow.fillColor = UIColor.black.withAlphaComponent(0.28)
        shadow.strokeColor = .clear
        shadow.position.y = -7
        container.addChild(shadow)

        let gate = SKShapeNode(rectOf: CGSize(width: (size.width - 62) / 2, height: 82), cornerRadius: 15)
        gate.fillColor = color.withAlphaComponent(0.92)
        gate.strokeColor = color.lighter()
        gate.lineWidth = 3
        gate.glowWidth = 2
        container.addChild(gate)

        let main = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        main.text = reward.label
        main.fontSize = 31
        main.verticalAlignmentMode = .center
        main.position.y = 8
        container.addChild(main)

        let sub = SKLabelNode(fontNamed: "AvenirNext-Bold")
        sub.text = reward.subtitle
        sub.fontSize = 9
        sub.fontColor = UIColor.white.withAlphaComponent(0.82)
        sub.position.y = -25
        container.addChild(sub)

        for direction in [-1.0, 1.0] {
            let post = SKShapeNode(rectOf: CGSize(width: 8, height: 108), cornerRadius: 4)
            post.fillColor = color.lighter()
            post.strokeColor = UIColor.white.withAlphaComponent(0.35)
            post.position.x = direction * ((size.width - 62) / 4 - 5)
            container.addChild(post)
        }
        return container
    }

    private func resolveGates() {
        for pair in world.children where pair.name == "gatePair" {
            guard abs(pair.position.y - squad.position.y) < 18,
                  pair.userData?["used"] as? Bool == false else { continue }
            pair.userData?["used"] = true
            let chosenName = squad.position.x < size.width / 2 ? "leftGate" : "rightGate"
            guard let chosen = pair.childNode(withName: chosenName) else { continue }
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
            for other in pair.children where other.name == "leftGate" || other.name == "rightGate" {
                if other !== chosen { other.alpha = 0.15 }
            }
        }
    }

    private func spawnFortress() {
        let node = SKNode()
        node.name = "fortress"
        node.position = CGPoint(x: size.width / 2, y: size.height + 155)
        fortressHealth = configuration.fortressHealth
        let shadow = SKShapeNode(ellipseOf: CGSize(width: size.width - 48, height: 50))
        shadow.fillColor = UIColor.black.withAlphaComponent(0.38)
        shadow.strokeColor = .clear
        shadow.position.y = -68
        node.addChild(shadow)
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
        for offset in [-size.width * 0.29, size.width * 0.29] {
            let tower = SKShapeNode(rectOf: CGSize(width: 52, height: 104), cornerRadius: 12)
            tower.fillColor = UIColor(red: 0.48, green: 0.10, blue: 0.12, alpha: 1)
            tower.strokeColor = UIColor(red: 0.95, green: 0.28, blue: 0.23, alpha: 1)
            tower.lineWidth = 3
            tower.position = CGPoint(x: offset, y: 10)
            node.addChild(tower)
            let cannon = SKShapeNode(circleOfRadius: 9)
            cannon.fillColor = .darkGray
            cannon.strokeColor = UIColor.white.withAlphaComponent(0.3)
            cannon.position = CGPoint(x: offset, y: -4)
            node.addChild(cannon)
        }
        let weakPoint = SKShapeNode(circleOfRadius: 19)
        weakPoint.name = "weakPoint"
        weakPoint.fillColor = UIColor(red: 1, green: 0.60, blue: 0.10, alpha: 1)
        weakPoint.strokeColor = UIColor.white.withAlphaComponent(0.8)
        weakPoint.lineWidth = 3
        weakPoint.glowWidth = 5
        weakPoint.run(.repeatForever(.sequence([.scale(to: 1.12, duration: 0.45), .scale(to: 0.92, duration: 0.45)])))
        node.addChild(weakPoint)
        let emblem = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        emblem.text = "FORTRESS"
        emblem.fontSize = 18
        emblem.verticalAlignmentMode = .center
        emblem.position.y = -43
        node.addChild(emblem)
        world.addChild(node)
        fortress = node
        flashStatus("BREAK THE FORTRESS")
        notify(.warning)
    }

    private func resolveCombat(delta: TimeInterval) {
        let enemies = world.children.filter { $0.name == "enemy" }
        let threats = ([fortress].compactMap { $0 } + enemies)
            .filter { $0.position.y > squad.position.y + 55 && $0.position.y < size.height + 35 }
        let alignedTargets = threats.filter { target in
            GameRules.isTargetAligned(
                squadX: Double(squad.position.x),
                targetX: Double(target.position.x),
                laneWidth: Double(fireLaneWidth),
                targetPadding: target.name == "fortress" ? 22 : 10
            )
        }
        let liveTarget = alignedTargets
            .min { $0.position.y < $1.position.y }
        threatPresent = !threats.isEmpty
        targetAligned = liveTarget != nil

        let locked = liveTarget != nil
        aimGuide.fillColor = locked
            ? UIColor(red: 1, green: 0.68, blue: 0.12, alpha: isRallying ? 0.16 : 0.08)
            : UIColor(red: 0.13, green: 0.71, blue: 0.93, alpha: isRallying ? 0.12 : 0.04)
        aimGuide.strokeColor = locked
            ? UIColor(red: 1, green: 0.76, blue: 0.18, alpha: 0.55)
            : UIColor(red: 0.20, green: 0.80, blue: 1, alpha: isRallying ? 0.5 : 0.14)

        if let target = liveTarget {
            let squadCount = max(0, Int(ceil(squadHealth)))
            let rallyMultiplier = isRallying ? 1.45 : 1
            let dps = (configuration.baseDamagePerSecond * damageMultiplier + Double(squadCount) * 0.64) * rallyMultiplier
            if target.name == "fortress" {
                fortressHealth -= dps * delta
                if fortressHealth <= 0 {
                    emitImpact(at: target.position, color: UIColor(red: 1, green: 0.52, blue: 0.14, alpha: 1), count: 18)
                    target.run(.sequence([.group([.scale(to: 1.18, duration: 0.18), .fadeOut(withDuration: 0.3)]), .removeFromParent()]))
                    finish(win: true)
                }
            } else if let health = target.userData?["health"] as? Double {
                let updated = health - dps * delta
                target.userData?["health"] = updated
                let fraction = max(0, updated / (target.userData?["maxHealth"] as? Double ?? 1))
                target.childNode(withName: "healthBar")?.childNode(withName: "healthFill")?.xScale = fraction
                if updated <= 0 {
                    let coinReward = target.userData?["coinReward"] as? Int ?? EnemyKind.rifleman.coinReward
                    let kind = (target.userData?["kind"] as? String).flatMap(EnemyKind.init(rawValue:)) ?? .rifleman
                    defeated += 1
                    killCoins += coinReward
                    score += 100 + coinReward * 20
                    target.name = "defeated"
                    emitImpact(at: target.position, color: UIColor(red: 0.96, green: 0.24, blue: 0.22, alpha: 1), count: 7)
                    showKillReward(at: target.position, coins: coinReward)
                    if kind == .brute {
                        flashStatus("BRUTE DOWN — +\(coinReward) COINS")
                        impact(.heavy)
                    }
                    target.run(.sequence([.group([.scale(to: 0.1, duration: 0.18), .fadeOut(withDuration: 0.18)]), .removeFromParent()]))
                }
            }
            if elapsed - lastShotTime > (isRallying ? 0.09 : 0.18) {
                fireTracer(at: target.position)
                emitImpact(at: target.position, color: UIColor(red: 1, green: 0.75, blue: 0.20, alpha: 1), count: 2)
                lastShotTime = elapsed
            }
        }

        for enemy in enemies where enemy.position.y > squad.position.y + 95 && enemy.position.y < size.height - 70 {
            guard enemy.userData?["canShoot"] as? Bool == true else { continue }
            let nextShot = enemy.userData?["nextShot"] as? Double ?? 0
            if elapsed >= nextShot {
                let projectileMultiplier = enemy.userData?["projectileMultiplier"] as? Double ?? 1
                spawnEnemyProjectile(from: enemy.position, damage: configuration.projectileDamage * projectileMultiplier)
                enemy.userData?["nextShot"] = elapsed + configuration.enemyFireInterval + Double.random(in: 0...0.65)
            }
        }

        let fortressFireInterval = configuration.isRecruitRun ? 1.4 : 0.9
        if let fortress, fortress.position.y < size.height - 90, elapsed - lastFortressShotTime > fortressFireInterval {
            spawnEnemyProjectile(
                from: CGPoint(x: fortress.position.x + (Bool.random() ? -size.width * 0.29 : size.width * 0.29), y: fortress.position.y),
                damage: configuration.projectileDamage * 1.25
            )
            lastFortressShotTime = elapsed
        }

        let attackers = enemies.filter {
            abs($0.position.y - squad.position.y) < 58 && abs($0.position.x - squad.position.x) < 105
        }
        if !attackers.isEmpty {
            let contactStrength = attackers.reduce(0.0) { total, enemy in
                total + (enemy.userData?["contactMultiplier"] as? Double ?? 1)
            }
            squadHealth -= contactStrength * delta * configuration.contactDamagePerSecond * (1 - configuration.damageResistance)
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
        tracer.lineWidth = isRallying ? 3 : 2
        tracer.glowWidth = isRallying ? 6 : 3
        tracer.zPosition = 20
        tracer.run(.sequence([.fadeOut(withDuration: 0.08), .removeFromParent()]))
        addChild(tracer)
    }

    private func spawnEnemyProjectile(from origin: CGPoint, damage: Double) {
        let projectile = SKShapeNode(circleOfRadius: damage > 1 ? 8 : 5)
        projectile.name = "enemyProjectile"
        projectile.position = origin
        projectile.fillColor = UIColor(red: 1, green: 0.22, blue: 0.16, alpha: 1)
        projectile.strokeColor = UIColor(red: 1, green: 0.70, blue: 0.24, alpha: 1)
        projectile.lineWidth = 2
        projectile.glowWidth = 5
        projectile.zPosition = 30

        let deltaX = squad.position.x - origin.x
        let deltaY = squad.position.y - origin.y
        let distance = max(1, hypot(deltaX, deltaY))
        let speed: CGFloat = damage > 1 ? 285 : 245
        projectile.userData = [
            "velocityX": deltaX / distance * speed,
            "velocityY": deltaY / distance * speed,
            "damage": damage
        ]
        addChild(projectile)

        let warningPath = CGMutablePath()
        warningPath.move(to: origin)
        warningPath.addLine(to: squad.position)
        let warning = SKShapeNode(path: warningPath)
        warning.strokeColor = UIColor(red: 1, green: 0.20, blue: 0.18, alpha: 0.26)
        warning.lineWidth = 1
        warning.zPosition = 12
        warning.run(.sequence([.fadeOut(withDuration: 0.22), .removeFromParent()]))
        addChild(warning)
    }

    private func updateEnemyProjectiles(delta: TimeInterval) {
        for projectile in children.filter({ $0.name == "enemyProjectile" }) {
            let velocityX = projectile.userData?["velocityX"] as? CGFloat ?? 0
            let velocityY = projectile.userData?["velocityY"] as? CGFloat ?? -240
            projectile.position.x += velocityX * delta
            projectile.position.y += velocityY * delta

            let squadWidth = min(78, 28 + CGFloat(sqrt(Double(max(1, soldiers.count)))) * 11)
            if abs(projectile.position.y - squad.position.y) < 25,
               abs(projectile.position.x - squad.position.x) < squadWidth {
                let damage = projectile.userData?["damage"] as? Double ?? 1
                squadHealth -= damage * (1 - configuration.damageResistance)
                emitImpact(at: projectile.position, color: UIColor(red: 1, green: 0.24, blue: 0.18, alpha: 1), count: 8)
                projectile.removeFromParent()
                rebuildSquad()
                impact(.medium)
            } else if projectile.position.y < -30 || projectile.position.x < -30 || projectile.position.x > size.width + 30 {
                projectile.removeFromParent()
            }
        }
    }

    private func resolveHazards() {
        for hazard in world.children.filter({ $0.name == "hazard" }) {
            guard abs(hazard.position.y - squad.position.y) < 28 else { continue }
            if abs(hazard.position.x - squad.position.x) < 62 {
                squadHealth -= configuration.hazardDamage * (1 - configuration.damageResistance)
                emitImpact(at: hazard.position, color: UIColor(red: 1, green: 0.35, blue: 0.12, alpha: 1), count: 14)
                flashStatus("MINE HIT — MOVE!")
                rebuildSquad()
                notify(.error)
            } else {
                score += 50
            }
            hazard.removeFromParent()
        }
    }

    private func emitImpact(at position: CGPoint, color: UIColor, count: Int) {
        for _ in 0..<count {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.5))
            particle.fillColor = color
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 40
            let move = SKAction.moveBy(x: CGFloat.random(in: -28...28), y: CGFloat.random(in: -18...34), duration: Double.random(in: 0.18...0.34))
            particle.run(.sequence([.group([move, .fadeOut(withDuration: 0.3), .scale(to: 0.2, duration: 0.3)]), .removeFromParent()]))
            addChild(particle)
        }
    }

    private func showKillReward(at worldPosition: CGPoint, coins: Int) {
        let reward = SKNode()
        reward.position = world.convert(worldPosition, to: self)
        reward.zPosition = 60

        let coin = SKShapeNode(circleOfRadius: 11)
        coin.fillColor = UIColor(red: 1, green: 0.69, blue: 0.10, alpha: 1)
        coin.strokeColor = UIColor(red: 1, green: 0.90, blue: 0.44, alpha: 1)
        coin.lineWidth = 2
        coin.glowWidth = 3
        reward.addChild(coin)

        let mark = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        mark.text = "+\(coins)"
        mark.fontSize = 13
        mark.fontColor = .white
        mark.verticalAlignmentMode = .center
        mark.position.x = 25
        reward.addChild(mark)

        reward.run(.sequence([
            .group([.moveBy(x: 0, y: 42, duration: 0.7), .fadeOut(withDuration: 0.7)]),
            .removeFromParent()
        ]))
        addChild(reward)
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
            let soldier = makeSoldier(color: color, enemy: false, walkCadence: 0.27)
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

    private func makeEnemy(kind: EnemyKind) -> SKNode {
        let color: UIColor = switch kind {
        case .rifleman: UIColor(red: 0.91, green: 0.20, blue: 0.24, alpha: 1)
        case .scout: UIColor(red: 1, green: 0.43, blue: 0.12, alpha: 1)
        case .shield: UIColor(red: 0.68, green: 0.12, blue: 0.24, alpha: 1)
        case .brute: UIColor(red: 0.48, green: 0.07, blue: 0.10, alpha: 1)
        }
        if kind == .brute { return makeBrute(color: color) }

        let cadence: TimeInterval = kind == .scout ? 0.15 : (kind == .shield ? 0.34 : 0.23)
        let enemy = makeSoldier(color: color, enemy: true, walkCadence: cadence)

        switch kind {
        case .rifleman:
            break
        case .scout:
            enemy.setScale(0.86)
            let antenna = SKShapeNode(rectOf: CGSize(width: 2, height: 10), cornerRadius: 1)
            antenna.fillColor = color
            antenna.strokeColor = .clear
            antenna.position = CGPoint(x: 5, y: 23)
            antenna.zRotation = -0.35
            enemy.addChild(antenna)
            let signal = SKShapeNode(circleOfRadius: 2.5)
            signal.fillColor = color
            signal.strokeColor = .clear
            signal.position = CGPoint(x: 7, y: 28)
            signal.glowWidth = 2
            enemy.addChild(signal)
            addEnemyTag("SCOUT", color: color, to: enemy)
        case .shield:
            enemy.setScale(1.08)
            let shieldPath = CGMutablePath()
            shieldPath.move(to: CGPoint(x: -13, y: -6))
            shieldPath.addLine(to: CGPoint(x: 13, y: -6))
            shieldPath.addLine(to: CGPoint(x: 10, y: -24))
            shieldPath.addLine(to: CGPoint(x: 0, y: -30))
            shieldPath.addLine(to: CGPoint(x: -10, y: -24))
            shieldPath.closeSubpath()
            let shield = SKShapeNode(path: shieldPath)
            shield.fillColor = color
            shield.strokeColor = color.lighter()
            shield.lineWidth = 2
            shield.position = CGPoint(x: 0, y: 1)
            shield.zPosition = 4
            enemy.addChild(shield)
            addEnemyTag("GUARD", color: color, to: enemy)
        case .brute:
            break
        }
        return enemy
    }

    private func makeSoldier(color: UIColor, enemy: Bool, walkCadence: TimeInterval) -> SKNode {
        let node = SKNode()
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 24, height: 10))
        shadow.fillColor = UIColor.black.withAlphaComponent(0.32)
        shadow.strokeColor = .clear
        shadow.position.y = -15
        shadow.zPosition = -2
        node.addChild(shadow)

        for direction in [-1.0, 1.0] {
            let side = direction < 0 ? "left" : "right"
            let leg = SKShapeNode(rectOf: CGSize(width: 7, height: 19), cornerRadius: 3.5)
            leg.name = "\(side)Leg"
            leg.fillColor = color
            leg.strokeColor = .clear
            leg.position = CGPoint(x: direction * 4.5, y: -16)
            leg.zRotation = direction * 0.06
            node.addChild(leg)

            let arm = SKShapeNode(rectOf: CGSize(width: 6, height: 21), cornerRadius: 3)
            arm.name = "\(side)Arm"
            arm.fillColor = color
            arm.strokeColor = .clear
            arm.position = CGPoint(x: direction * 11.5, y: 0)
            arm.zRotation = direction * -0.10
            node.addChild(arm)
        }

        let torso = SKShapeNode(rectOf: CGSize(width: 21, height: 24), cornerRadius: 8)
        torso.name = "torso"
        torso.fillColor = color
        torso.strokeColor = .clear
        torso.position.y = 0.5
        node.addChild(torso)

        let head = SKShapeNode(circleOfRadius: 9)
        head.name = "head"
        head.position.y = 20
        head.fillColor = color
        head.strokeColor = .clear
        node.addChild(head)

        let weapon = SKShapeNode(rectOf: CGSize(width: 3, height: 18), cornerRadius: 1.5)
        weapon.name = "weapon"
        weapon.position = CGPoint(x: enemy ? -10 : 10, y: enemy ? -7 : 7)
        weapon.fillColor = .darkGray
        weapon.strokeColor = .clear
        node.addChild(weapon)
        let muzzle = SKShapeNode(circleOfRadius: 2)
        muzzle.fillColor = UIColor(red: 1, green: 0.69, blue: 0.16, alpha: 0.9)
        muzzle.strokeColor = .clear
        muzzle.name = "muzzle"
        muzzle.position = CGPoint(x: enemy ? -10 : 10, y: enemy ? -17 : 17)
        node.addChild(muzzle)
        node.zPosition = enemy ? 5 : 10
        addWalkAnimation(to: node, cadence: walkCadence)
        return node
    }

    private func makeBrute(color: UIColor) -> SKNode {
        let node = SKNode()
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 58, height: 18))
        shadow.fillColor = UIColor.black.withAlphaComponent(0.45)
        shadow.strokeColor = .clear
        shadow.position.y = -27
        shadow.zPosition = -2
        node.addChild(shadow)

        for direction in [-1.0, 1.0] {
            let side = direction < 0 ? "left" : "right"
            let leg = SKShapeNode(rectOf: CGSize(width: 12, height: 29), cornerRadius: 6)
            leg.name = "\(side)Leg"
            leg.fillColor = color
            leg.strokeColor = .clear
            leg.position = CGPoint(x: direction * 10, y: -20)
            node.addChild(leg)

            let arm = SKShapeNode(rectOf: CGSize(width: 12, height: 36), cornerRadius: 6)
            arm.name = "\(side)Arm"
            arm.fillColor = color
            arm.strokeColor = .clear
            arm.position = CGPoint(x: direction * 25, y: 0)
            arm.zRotation = direction * -0.22
            node.addChild(arm)

            let claw = SKShapeNode(circleOfRadius: 8)
            claw.fillColor = color
            claw.strokeColor = .clear
            claw.position = CGPoint(x: direction * 30, y: -18)
            node.addChild(claw)

            let hornPath = CGMutablePath()
            hornPath.move(to: CGPoint(x: 0, y: 0))
            hornPath.addLine(to: CGPoint(x: direction * 13, y: 13))
            hornPath.addLine(to: CGPoint(x: direction * 5, y: -4))
            hornPath.closeSubpath()
            let horn = SKShapeNode(path: hornPath)
            horn.fillColor = color
            horn.strokeColor = .clear
            horn.position = CGPoint(x: direction * 8, y: 37)
            node.addChild(horn)
        }

        let torso = SKShapeNode(rectOf: CGSize(width: 44, height: 39), cornerRadius: 13)
        torso.name = "torso"
        torso.fillColor = color
        torso.strokeColor = .clear
        torso.position.y = 1
        node.addChild(torso)

        let head = SKShapeNode(ellipseOf: CGSize(width: 30, height: 25))
        head.name = "head"
        head.fillColor = color
        head.strokeColor = .clear
        head.position.y = 31
        node.addChild(head)

        for direction in [-1.0, 1.0] {
            let eye = SKShapeNode(circleOfRadius: 3)
            eye.fillColor = UIColor(red: 1, green: 0.64, blue: 0.08, alpha: 1)
            eye.strokeColor = .clear
            eye.glowWidth = 4
            eye.position = CGPoint(x: direction * 6, y: 32)
            node.addChild(eye)
        }
        let mouth = SKShapeNode(rectOf: CGSize(width: 15, height: 3), cornerRadius: 1.5)
        mouth.fillColor = UIColor.black.withAlphaComponent(0.7)
        mouth.strokeColor = .clear
        mouth.position.y = 24
        node.addChild(mouth)

        let badge = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        badge.text = "BRUTE"
        badge.fontSize = 8
        badge.fontColor = UIColor(red: 1, green: 0.66, blue: 0.22, alpha: 1)
        badge.position.y = 52
        node.addChild(badge)

        node.setScale(1.25)
        node.zPosition = 6
        addWalkAnimation(to: node, cadence: 0.38)
        return node
    }

    private func addEnemyTag(_ text: String, color: UIColor, to enemy: SKNode) {
        let tag = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        tag.text = text
        tag.fontSize = 7
        tag.fontColor = color.lighter()
        tag.position.y = 39
        enemy.addChild(tag)
    }

    private func addWalkAnimation(to node: SKNode, cadence: TimeInterval) {
        let phase = Double.random(in: 0...(cadence * 2))
        for side in ["left", "right"] {
            let leading = side == "left"
            let legAngles: [CGFloat] = leading ? [-0.24, 0.24, -0.24] : [0.24, -0.24, 0.24]
            let armAngles: [CGFloat] = leading ? [0.20, -0.20, 0.20] : [-0.20, 0.20, -0.20]
            let legSwing = SKAction.sequence(legAngles.map { .rotate(toAngle: $0, duration: cadence) })
            let armSwing = SKAction.sequence(armAngles.map { .rotate(toAngle: $0, duration: cadence) })
            node.childNode(withName: "\(side)Leg")?.run(.sequence([.wait(forDuration: phase), .repeatForever(legSwing)]))
            node.childNode(withName: "\(side)Arm")?.run(.sequence([.wait(forDuration: phase), .repeatForever(armSwing)]))
        }

        let bob = SKAction.sequence([
            .moveBy(x: 0, y: 1.5, duration: cadence),
            .moveBy(x: 0, y: -1.5, duration: cadence)
        ])
        node.childNode(withName: "torso")?.run(.repeatForever(bob))
        node.childNode(withName: "head")?.run(.repeatForever(bob.reversed()))
        node.childNode(withName: "weapon")?.run(.repeatForever(.sequence([
            .rotate(toAngle: 0.10, duration: cadence),
            .rotate(toAngle: -0.10, duration: cadence)
        ])))
    }

    private func makeHealthBar(width: CGFloat) -> SKNode {
        let bar = SKNode()
        bar.name = "healthBar"
        bar.position.y = 29

        let background = SKShapeNode(rectOf: CGSize(width: width + 4, height: 6), cornerRadius: 3)
        background.fillColor = UIColor.black.withAlphaComponent(0.55)
        background.strokeColor = UIColor.white.withAlphaComponent(0.12)
        background.lineWidth = 1
        bar.addChild(background)

        let fill = SKShapeNode(rectOf: CGSize(width: width, height: 3), cornerRadius: 1.5)
        fill.name = "healthFill"
        fill.fillColor = UIColor(red: 1, green: 0.34, blue: 0.28, alpha: 1)
        fill.strokeColor = .clear
        bar.addChild(fill)
        return bar
    }

    private func announceNewEnemyType(in roster: [EnemyKind]) {
        guard let kind = roster.first(where: { $0 != .rifleman && !announcedEnemyKinds.contains($0) }) else { return }
        announcedEnemyKinds.insert(kind)
        let message: String = switch kind {
        case .rifleman: "RIFLEMEN INBOUND"
        case .scout: "SCOUTS — QUICK SHOTS"
        case .shield: "GUARDS — BREAK THEIR SHIELDS"
        case .brute: "BRUTE INBOUND — WORTH 10 COINS"
        }
        flashStatus(message)
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
        let rallyCharge = isRallying ? 1 : min(1, max(0, (elapsed - lastRallyTime) / rallyCooldown))
        onHUDChange?(BattleHUD(
            squadCount: max(0, Int(ceil(squadHealth))),
            score: score,
            coinsEarned: killCoins,
            progress: min(1, elapsed / runDuration),
            bossHealthFraction: bossFraction,
            statusText: status,
            rallyCharge: rallyCharge,
            isRallying: isRallying,
            threatPresent: threatPresent,
            targetAligned: targetAligned
        ))
    }

    private func finish(win: Bool) {
        guard !didFinish else { return }
        didFinish = true
        isPaused = true
        let remaining = max(0, Int(ceil(squadHealth)))
        let finalScore = GameRules.score(didWin: win, defeated: defeated, remaining: remaining)
        let reward = GameRules.reward(didWin: win, killCoins: killCoins, remaining: remaining)
        let result = RunResult(
            didWin: win,
            score: finalScore,
            coinsEarned: reward,
            killCoinsEarned: killCoins,
            survivalCoins: remaining,
            completionBonus: win ? 35 : 12,
            enemiesDefeated: defeated,
            squadRemaining: remaining
        )
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

    func darker() -> UIColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return UIColor(red: max(0, red - 0.18), green: max(0, green - 0.18), blue: max(0, blue - 0.18), alpha: alpha)
    }
}
