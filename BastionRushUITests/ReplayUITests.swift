import XCTest

final class ReplayUITests: XCTestCase {
    @MainActor
    func testCaptureAppStorePreview() throws {
        guard ProcessInfo.processInfo.environment["CAPTURE_APP_PREVIEW"] == "1" else {
            throw XCTSkip("Only runs while recording App Store media.")
        }

        let app = XCUIApplication()
        app.launchArguments = ["-launchGame"]
        app.launch()

        let surface = app.otherElements["gameplaySurface"]
        XCTAssertTrue(surface.waitForExistence(timeout: 5))
        let left = surface.coordinate(withNormalizedOffset: CGVector(dx: 0.22, dy: 0.72))
        let center = surface.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.72))
        let right = surface.coordinate(withNormalizedOffset: CGVector(dx: 0.78, dy: 0.72))

        center.press(forDuration: 0.1, thenDragTo: left)
        Thread.sleep(forTimeInterval: 3.0)
        left.press(forDuration: 0.1, thenDragTo: right)
        Thread.sleep(forTimeInterval: 4.0)
        if app.buttons["Activate Rally"].isEnabled { app.buttons["Activate Rally"].tap() }
        Thread.sleep(forTimeInterval: 3.0)
        right.press(forDuration: 0.1, thenDragTo: center)
        Thread.sleep(forTimeInterval: 4.0)
        center.press(forDuration: 0.1, thenDragTo: left)
        Thread.sleep(forTimeInterval: 4.0)
        left.press(forDuration: 0.1, thenDragTo: right)
        Thread.sleep(forTimeInterval: 4.0)
    }

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
