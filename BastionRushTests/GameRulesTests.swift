import Testing
@testable import BastionRush

struct GameRulesTests {
    @Test func upgradeCostsIncrease() {
        #expect(GameRules.upgradeCost(level: 0) == 35)
        #expect(GameRules.upgradeCost(level: 2) > GameRules.upgradeCost(level: 1))
    }

    @Test func winningPaysABonus() {
        let loss = GameRules.reward(didWin: false, killCoins: 20, remaining: 3)
        let win = GameRules.reward(didWin: true, killCoins: 20, remaining: 3)
        #expect(win - loss == 23)
    }

    @Test func earlyLossStillFundsProgress() {
        #expect(GameRules.reward(didWin: false, killCoins: 0, remaining: 0) == 12)
    }

    @Test func everyKillCoinIsIncludedInThePayout() {
        let noKills = GameRules.reward(didWin: false, killCoins: 0, remaining: 2)
        let mixedKills = GameRules.reward(didWin: false, killCoins: 17, remaining: 2)
        #expect(mixedKills - noKills == 17)
    }

    @Test func defenderTypesUnlockAsLevelsAdvance() {
        let levelOneEarly = GameRules.defenderRoster(level: 0, elapsed: 8, count: 5, brutesSpawned: 0)
        let levelOneLate = GameRules.defenderRoster(level: 0, elapsed: 23, count: 5, brutesSpawned: 0)
        let levelThree = GameRules.defenderRoster(level: 2, elapsed: 23, count: 8, brutesSpawned: 0)

        #expect(Set(levelOneEarly) == [.rifleman])
        #expect(levelOneLate.filter { $0 == .brute }.count == 1)
        #expect(levelThree.contains(.scout))
        #expect(levelThree.contains(.shield))
        #expect(levelThree.contains(.brute))
        #expect(EnemyKind.brute.coinReward > EnemyKind.rifleman.coinReward)
    }

    @Test func scoreRewardsSurvivors() {
        #expect(GameRules.score(didWin: false, defeated: 5, remaining: 4) == 700)
    }

    @Test func shotsOnlyHitTargetsInsideTheFireLane() {
        #expect(GameRules.isTargetAligned(squadX: 200, targetX: 238, laneWidth: 68, targetPadding: 10))
        #expect(!GameRules.isTargetAligned(squadX: 200, targetX: 260, laneWidth: 68, targetPadding: 10))
    }

    @Test func recruitDifficultyIsForgivingThenRamps() {
        let recruit = BattleConfiguration(startingSquad: 8, baseDamagePerSecond: 5.2, damageResistance: 0, level: 0, skin: .cobalt, hapticsEnabled: true)
        let veteran = BattleConfiguration(startingSquad: 8, baseDamagePerSecond: 5.2, damageResistance: 0, level: 4, skin: .cobalt, hapticsEnabled: true)

        #expect(recruit.fortressHealth < veteran.fortressHealth)
        #expect(recruit.baseFireLaneWidth > veteran.baseFireLaneWidth)
        #expect(recruit.projectileDamage < veteran.projectileDamage)
        #expect(recruit.hazardDamage < veteran.hazardDamage)
        #expect(recruit.contactDamagePerSecond < veteran.contactDamagePerSecond)
        #expect(recruit.shooterStride > veteran.shooterStride)
        #expect(recruit.isRecruitRun)
        #expect(!veteran.isRecruitRun)
    }
}
