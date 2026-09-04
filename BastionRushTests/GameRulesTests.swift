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

    @Test func scoreRewardsSurvivors() {
        #expect(GameRules.score(didWin: false, defeated: 5, remaining: 4) == 700)
    }
}
