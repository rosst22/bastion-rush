import XCTest

final class ReplayUITests: XCTestCase {
    @MainActor
    func testPauseStopsAndResumesTheLevel() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-launchGame"]
        app.launch()

        let pause = app.buttons["pauseLevelButton"]
        XCTAssertTrue(pause.waitForExistence(timeout: 5))
        pause.tap()

        let resume = app.buttons["continueLevelButton"]
        XCTAssertTrue(resume.waitForExistence(timeout: 2))
        resume.tap()
        XCTAssertTrue(pause.waitForExistence(timeout: 2))
    }

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
