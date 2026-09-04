import Foundation

struct BattleConfiguration: Equatable {
    let startingSquad: Int
    let baseDamagePerSecond: Double
    let damageResistance: Double
    let level: Int
    let skin: SquadSkin
    let hapticsEnabled: Bool

    var fortressHealth: Double { 150 + Double(level) * 18 }
    var enemyHealthMultiplier: Double { 1 + Double(level) * 0.08 }
}

struct BattleHUD: Equatable {
    var squadCount: Int
    var score: Int
    var progress: Double
    var bossHealthFraction: Double?
    var statusText: String?
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
