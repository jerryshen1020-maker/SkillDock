import XCTest

final class EmptyLoadingErrorUITests: XCTestCase {
    func testSkillsRepositoryPageCanLaunch() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }

    func testSwitchAppDoesNotShowToast() {
        let app = XCUIApplication()
        app.launchArguments += ["-uitest_mode", "-uitest_visual_snapshot"]
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        let switchButton = app.buttons["app-target-codex"].firstMatch
        XCTAssertTrue(switchButton.waitForExistence(timeout: 2))
        switchButton.click()
        let successToast = app.descendants(matching: .any).matching(identifier: "toast-success").firstMatch
        XCTAssertFalse(successToast.waitForExistence(timeout: 2))
    }

    func testUnavailableSourceBannerCanBeDisplayed() {
        let app = XCUIApplication()
        app.launchArguments += ["-uitest_mode", "-uitest_seed_unavailable_source"]
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        let sourceTabButton = app.buttons["sidebar-source-management"].firstMatch
        if sourceTabButton.waitForExistence(timeout: 1) {
            sourceTabButton.click()
        }
        let unavailableBanner = app.descendants(matching: .any).matching(identifier: "unavailable-sources-banner").firstMatch
        XCTAssertTrue(unavailableBanner.waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["UI Test Unavailable"].exists)
    }
}
