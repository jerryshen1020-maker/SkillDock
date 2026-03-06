import XCTest

final class EmptyLoadingErrorUITests: XCTestCase {
    func testSkillsRepositoryPageCanLaunch() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }

    func testWarningToastCanBeDisplayed() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        let switchButton = app.buttons["app-target-codex"].firstMatch
        XCTAssertTrue(switchButton.waitForExistence(timeout: 2))
        switchButton.click()
        XCTAssertTrue(app.staticTexts["已切换应用：Codex"].waitForExistence(timeout: 2))
    }

    func testUnavailableSourceBannerCanBeDisplayed() {
        let app = XCUIApplication()
        app.launchArguments += ["-uitest_mode", "-uitest_seed_unavailable_source"]
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        let sourceTabButton = app.buttons["来源管理"].firstMatch
        if sourceTabButton.waitForExistence(timeout: 1) {
            sourceTabButton.click()
        }
        XCTAssertTrue(app.staticTexts["有来源暂不可用"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["UI Test Unavailable"].exists)
    }
}
