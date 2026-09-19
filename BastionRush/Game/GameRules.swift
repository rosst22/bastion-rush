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
        case 0: 145
        case 1: 205
        default: 235 + Double(level) * 28
        }
    }
    var enemyHealthMultiplier: Double {
        switch level {
        case 0: 0.66
        case 1: 0.88
        default: 1 + Double(level - 2) * 0.10
        }
    }
    var baseFireLaneWidth: Double { level == 0 ? 100 : (level == 1 ? 86 : 72) }
    var waveInterval: Double { max(2.05, (level == 0 ? 3.7 : 3.25) - Double(level) * 0.06) }
    var baseWaveCount: Int { level == 0 ? 2 : 3 }
    var maxWaveCount: Int { level == 0 ? 6 : min(10, 7 + level) }
    var shooterStride: Int { level == 0 ? 3 : (level == 1 ? 2 : 1) }
    var projectileDamage: Double { level == 0 ? 0.55 : min(1.15, 0.82 + Double(level) * 0.06) }
    var hazardDamage: Double { level == 0 ? 1.0 : min(2.3, 1.6 + Double(level) * 0.08) }
    var contactDamagePerSecond: Double { level == 0 ? 0.9 : min(1.8, 1.35 + Double(level) * 0.06) }
    var enemyFireInterval: Double { max(1.15, level == 0 ? 2.65 : 2.15 - Double(level) * 0.04) }
}

struct BattleHUD: Equatable {
    var squadCount: Int
    var score: Int
    var coinsEarned: Int
    var progress: Double
    var bossHealthFraction: Double?
    var statusText: String?
    var rallyCharge: Double
    var isRallying: Bool
    var threatPresent: Bool
    var targetAligned: Bool
}

enum EnemyKind: String, Equatable, Hashable {
    case rifleman
    case scout
    case shield
    case brute

    var baseHealth: Double {
        switch self {
        case .rifleman: 15
        case .scout: 10
        case .shield: 27
        case .brute: 44
        }
    }

    var coinReward: Int {
        switch self {
        case .rifleman: 2
        case .scout: 3
        case .shield: 5
        case .brute: 10
        }
    }

    var contactMultiplier: Double {
        switch self {
        case .rifleman: 1
        case .scout: 0.75
        case .shield: 1.15
        case .brute: 1.65
        }
    }

    var projectileMultiplier: Double {
        switch self {
        case .rifleman: 1
        case .scout: 0.72
        case .shield: 0
        case .brute: 1.15
        }
    }
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

    static func defenderRoster(level: Int, elapsed: Double, count: Int, brutesSpawned: Int) -> [EnemyKind] {
        let bruteStart = max(11, 20 - Double(level) * 2)
        let bruteLimit = 1 + level / 2

        return (0..<count).map { index in
            if index == count - 1, elapsed >= bruteStart, brutesSpawned < bruteLimit {
                return .brute
            }
            if level >= 2, index % 4 == 2 {
                return .shield
            }
            if level >= 1, index % 3 == 1 {
                return .scout
            }
            return .rifleman
        }
    }

    static func reward(didWin: Bool, killCoins: Int, remaining: Int) -> Int {
        killCoins + remaining + (didWin ? 35 : 12)
    }

    static func score(didWin: Bool, defeated: Int, remaining: Int) -> Int {
        defeated * 100 + remaining * 50 + (didWin ? 2_500 : 0)
    }
}
