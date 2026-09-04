import Testing
@testable import BastionRush

struct GameRulesTests {
    @Test func upgradeCostsIncrease() {
        #expect(GameRules.upgradeCost(level: 0) == 35)
        #expect(GameRules.upgradeCost(level: 2) > GameRules.upgradeCost(level: 1))
    }

    @Test func winningPaysABonus() {
        let loss = GameRules.reward(didWin: false, defeated: 10, remaining: 3)
        let win = GameRules.reward(didWin: true, defeated: 10, remaining: 3)
        #expect(win - loss == 35)
    }

    @Test func earlyLossStillFundsProgress() {
        #expect(GameRules.reward(didWin: false, defeated: 0, remaining: 0) == 12)
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
        #expect(recruit.shooterStride > veteran.shooterStride)
        #expect(recruit.isRecruitRun)
        #expect(!veteran.isRecruitRun)
    }
}
