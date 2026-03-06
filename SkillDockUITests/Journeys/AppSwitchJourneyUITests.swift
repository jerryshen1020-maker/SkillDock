import XCTest

final class AppSwitchJourneyUITests: XCTestCase {
    func testAppLaunchesSuccessfully() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
}
