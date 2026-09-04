import Foundation

struct BattleConfiguration: Equatable {
    let startingSquad: Int
    let baseDamagePerSecond: Double
    let damageResistance: Double
    let level: Int
    let skin: SquadSkin
    let hapticsEnabled: Bool

    var isRecruitRun: Bool { level < 2 }
    var fortressHealth: Double {
        switch level {
        case 0: 165
        case 1: 205
        default: 235 + Double(level) * 28
        }
    }
    var enemyHealthMultiplier: Double {
        switch level {
        case 0: 0.72
        case 1: 0.88
        default: 1 + Double(level - 2) * 0.10
        }
    }
    var baseFireLaneWidth: Double { level == 0 ? 100 : (level == 1 ? 86 : 72) }
    var waveInterval: Double { max(2.05, (level == 0 ? 3.7 : 3.25) - Double(level) * 0.06) }
    var baseWaveCount: Int { level == 0 ? 2 : 3 }
    var maxWaveCount: Int { level == 0 ? 6 : min(10, 7 + level) }
    var shooterStride: Int { level == 0 ? 3 : (level == 1 ? 2 : 1) }
    var projectileDamage: Double { level == 0 ? 0.65 : min(1.15, 0.82 + Double(level) * 0.06) }
    var hazardDamage: Double { level == 0 ? 1.25 : min(2.3, 1.6 + Double(level) * 0.08) }
    var contactDamagePerSecond: Double { level == 0 ? 1.05 : min(1.8, 1.35 + Double(level) * 0.06) }
    var enemyFireInterval: Double { max(1.15, level == 0 ? 2.65 : 2.15 - Double(level) * 0.04) }
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
        max(didWin ? 35 : 12, defeated * 2 + remaining + (didWin ? 35 : 0))
    }

    static func score(didWin: Bool, defeated: Int, remaining: Int) -> Int {
        defeated * 100 + remaining * 50 + (didWin ? 2_500 : 0)
    }
}
