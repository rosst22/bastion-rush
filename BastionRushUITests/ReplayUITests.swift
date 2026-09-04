import XCTest

final class ReplayUITests: XCTestCase {
    @MainActor
    func testRunItBackStartsAFreshScene() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-launchGame", "-instantDefeat"]
        app.launch()

        let replay = app.buttons["runItBackButton"]
        XCTAssertTrue(replay.waitForExistence(timeout: 5))
        replay.tap()

        let replayDisappeared = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: replay
        )
        XCTAssertEqual(XCTWaiter.wait(for: [replayDisappeared], timeout: 2), .completed)
        XCTAssertTrue(app.buttons["Activate Rally"].waitForExistence(timeout: 2))
    }
}
