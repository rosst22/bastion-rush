import Foundation

struct BattleConfiguration: Equatable {
    let startingSquad: Int
    let baseDamagePerSecond: Double
    let damageResistance: Double
    let level: Int
    let skin: SquadSkin
    let hapticsEnabled: Bool

    var fortressHealth: Double { 250 + Double(level) * 30 }
    var enemyHealthMultiplier: Double { 1 + Double(level) * 0.12 }
}

struct BattleHUD: Equatable {
    var squadCount: Int
    var score: Int
    var progress: Double
    var bossHealthFraction: Double?
    var statusText: String?
    var rallyCharge: Double
    var isRallying: Bool
    var threatPresent: Bool
    var targetAligned: Bool
}

enum GateReward: Equatable {
    case recruits(Int)
    case damage(Double)

    var label: String {
        switch self {
        case .recruits(let count): "+\(count)"
        case .damage(let multiplier): "×\(String(format: "%.1f", multiplier))"
        }
    }

    var subtitle: String {
        switch self {
        case .recruits: "TROOPS"
        case .damage: "POWER"
        }
    }
}

enum GameRules {
    static func isTargetAligned(squadX: Double, targetX: Double, laneWidth: Double, targetPadding: Double) -> Bool {
        abs(targetX - squadX) <= laneWidth / 2 + targetPadding
    }

    static func upgradeCost(level: Int) -> Int {
        35 + level * level * 18 + level * 22
    }

    static func reward(didWin: Bool, defeated: Int, remaining: Int) -> Int {
        max(5, defeated * 2 + remaining + (didWin ? 35 : 0))
    }

    static func score(didWin: Bool, defeated: Int, remaining: Int) -> Int {
        defeated * 100 + remaining * 50 + (didWin ? 2_500 : 0)
    }
}
