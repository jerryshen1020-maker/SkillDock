import XCTest

final class VisualSnapshotCaptureUITests: XCTestCase {
    private var app: XCUIApplication!
    private let baseLaunchArguments = ["-uitest_mode", "-uitest_visual_snapshot", "-uitest_force_chinese"]

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += baseLaunchArguments
        app.launchArguments += ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        if let outputDir = ProcessInfo.processInfo.environment["VISUAL_OUTPUT_DIR"] {
            app.launchEnvironment["VISUAL_OUTPUT_DIR"] = outputDir
        }
        app.launch()
        ensureAppIsReady()
    }

    func testCaptureV12VisualSnapshots() throws {
        tapButtonWithID("app-target-claudeCode")
        
        tapButtonIfExists("sidebar-settings")
        tapButtonIfExists("浅色")

        tapButtonWithID("app-target-claudeCode")
        try saveScreenshot(
            named: "skills__empty__light__900x600.png",
            folder: "skills"
        )

        tapButtonIfExists("sidebar-source-management")
        try saveScreenshot(
            named: "source__default__light__900x600.png",
            folder: "source"
        )

        tapButtonIfExists("sidebar-settings")
        try saveScreenshot(
            named: "settings__default__light__900x600.png",
            folder: "settings"
        )

        tapButtonWithID("app-target-claudeCode")
        try saveScreenshot(
            named: "state__empty__light__900x600.png",
            folder: "states"
        )
    }

    func testCaptureV13StateSnapshots() throws {
        relaunch(with: ["-uitest_seed_toast_warning"])
        try saveScreenshot(
            named: "state__toast_warning__light__900x600.png",
            folder: "states"
        )

        relaunch(with: ["-uitest_seed_unavailable_source"])
        try saveScreenshot(
            named: "source__unavailable_banner__light__900x600.png",
            folder: "source"
        )
    }

    private func tapButtonWithID(_ identifier: String) {
        ensureAppIsReady()
        let button = app.buttons[identifier].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 3))
        button.click()
        RunLoop.current.run(until: Date().addingTimeInterval(0.35))
    }

    private func tapButtonIfExists(_ identifier: String) {
        ensureAppIsReady()
        let button = app.buttons[identifier].firstMatch
        if button.waitForExistence(timeout: 3) {
            button.click()
            RunLoop.current.run(until: Date().addingTimeInterval(0.35))
        }
    }

    private func relaunch(with additionalArguments: [String]) {
        app.terminate()
        app = XCUIApplication()
        app.launchArguments += baseLaunchArguments
        app.launchArguments += ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        app.launchArguments += additionalArguments
        if let outputDir = ProcessInfo.processInfo.environment["VISUAL_OUTPUT_DIR"] {
            app.launchEnvironment["VISUAL_OUTPUT_DIR"] = outputDir
        }
        app.launch()
        ensureAppIsReady()
    }

    private func saveScreenshot(named fileName: String, folder: String) throws {
        ensureAppIsReady()
        let outputDirectory = try makeOutputDirectory(folder: folder)
        let outputURL = outputDirectory.appendingPathComponent(fileName, isDirectory: false)
        let window = app.windows.firstMatch
        let screenshot = window.exists ? window.screenshot() : app.screenshot()
        try screenshot.pngRepresentation.write(to: outputURL)
        print("VISUAL_SNAPSHOT_WRITTEN \(outputURL.path)")
    }

    private func ensureAppIsReady() {
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5))
        RunLoop.current.run(until: Date().addingTimeInterval(0.45))
    }

    private func makeOutputDirectory(folder: String) throws -> URL {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("skilldock-visual-snapshots", isDirectory: true)
        let outputRoot = ProcessInfo.processInfo.environment["VISUAL_OUTPUT_DIR"]
            .map { URL(fileURLWithPath: $0, isDirectory: true) }
            ?? tempRoot
        let output = outputRoot.appendingPathComponent(folder, isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true, attributes: nil)
        return output
    }
}
