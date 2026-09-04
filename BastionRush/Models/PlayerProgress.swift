import Foundation
import Observation

@MainActor
@Observable
final class PlayerProgress {
    private enum Key {
        static let coins = "progress.coins"
        static let wins = "progress.wins"
        static let bestScore = "progress.bestScore"
        static let squadLevel = "progress.squadLevel"
        static let firepowerLevel = "progress.firepowerLevel"
        static let armorLevel = "progress.armorLevel"
        static let selectedSkin = "progress.selectedSkin"
    }

    var coins: Int { didSet { save() } }
    var wins: Int { didSet { save() } }
    var bestScore: Int { didSet { save() } }
    var squadLevel: Int { didSet { save() } }
    var firepowerLevel: Int { didSet { save() } }
    var armorLevel: Int { didSet { save() } }
    var selectedSkin: SquadSkin { didSet { save() } }

    private var isLoading = true

    init(
        coins: Int = 0,
        wins: Int = 0,
        bestScore: Int = 0,
        squadLevel: Int = 0,
        firepowerLevel: Int = 0,
        armorLevel: Int = 0,
        selectedSkin: SquadSkin = .cobalt
    ) {
        self.coins = coins
        self.wins = wins
        self.bestScore = bestScore
        self.squadLevel = squadLevel
        self.firepowerLevel = firepowerLevel
        self.armorLevel = armorLevel
        self.selectedSkin = selectedSkin
        isLoading = false
    }

    static func load(defaults: UserDefaults = .standard) -> PlayerProgress {
        PlayerProgress(
            coins: defaults.integer(forKey: Key.coins),
            wins: defaults.integer(forKey: Key.wins),
            bestScore: defaults.integer(forKey: Key.bestScore),
            squadLevel: defaults.integer(forKey: Key.squadLevel),
            firepowerLevel: defaults.integer(forKey: Key.firepowerLevel),
            armorLevel: defaults.integer(forKey: Key.armorLevel),
            selectedSkin: SquadSkin(rawValue: defaults.string(forKey: Key.selectedSkin) ?? "") ?? .cobalt
        )
    }

    var startingSquad: Int { 8 + squadLevel * 2 }
    var damagePerSecond: Double { 5.2 + Double(firepowerLevel) * 1.35 }
    var damageResistance: Double { min(0.45, Double(armorLevel) * 0.07) }

    func upgradeCost(for type: UpgradeType) -> Int {
        let level = level(for: type)
        return 35 + level * level * 18 + level * 22
    }

    func level(for type: UpgradeType) -> Int {
        switch type {
        case .squad: squadLevel
        case .firepower: firepowerLevel
        case .armor: armorLevel
        }
    }

    @discardableResult
    func buy(_ type: UpgradeType) -> Bool {
        let cost = upgradeCost(for: type)
        guard coins >= cost else { return false }
        coins -= cost
        switch type {
        case .squad: squadLevel += 1
        case .firepower: firepowerLevel += 1
        case .armor: armorLevel += 1
        }
        return true
    }

    func record(_ result: RunResult) {
        coins += result.coinsEarned
        bestScore = max(bestScore, result.score)
        if result.didWin { wins += 1 }
    }

    func reset() {
        coins = 0
        wins = 0
        bestScore = 0
        squadLevel = 0
        firepowerLevel = 0
        armorLevel = 0
        selectedSkin = .cobalt
    }

    private func save(defaults: UserDefaults = .standard) {
        guard !isLoading else { return }
        defaults.set(coins, forKey: Key.coins)
        defaults.set(wins, forKey: Key.wins)
        defaults.set(bestScore, forKey: Key.bestScore)
        defaults.set(squadLevel, forKey: Key.squadLevel)
        defaults.set(firepowerLevel, forKey: Key.firepowerLevel)
        defaults.set(armorLevel, forKey: Key.armorLevel)
        defaults.set(selectedSkin.rawValue, forKey: Key.selectedSkin)
    }
}

enum UpgradeType: String, CaseIterable, Identifiable {
    case squad
    case firepower
    case armor

    var id: String { rawValue }
    var title: String {
        switch self {
        case .squad: "Reinforcements"
        case .firepower: "Firepower"
        case .armor: "Field Armor"
        }
    }
    var subtitle: String {
        switch self {
        case .squad: "+2 starting troops"
        case .firepower: "+26% base damage"
        case .armor: "7% less contact damage"
        }
    }
    var symbol: String {
        switch self {
        case .squad: "person.3.fill"
        case .firepower: "scope"
        case .armor: "shield.fill"
        }
    }
}

enum SquadSkin: String, CaseIterable, Identifiable {
    case cobalt
    case ember
    case ivory

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct RunResult: Equatable {
    let didWin: Bool
    let score: Int
    let coinsEarned: Int
    let enemiesDefeated: Int
    let squadRemaining: Int
}
