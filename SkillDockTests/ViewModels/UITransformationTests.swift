import XCTest
@testable import SkillDock

@MainActor
final class UITransformationTests: XCTestCase {
    func testSelectedTabDefaultsToAppSkills() {
        let viewModel = MainViewModel(autoLoad: false)
        XCTAssertEqual(viewModel.selectedTab, .appSkills)
    }

    func testSourceSkillCountsTracksSkillsPerSource() throws {
        let suiteName = "UITransformationTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)

        let sourceA = try makeTempDirectory()
        let sourceB = try makeTempDirectory()
        let appSkills = try makeTempDirectory()
        defer {
            try? FileManager.default.removeItem(at: sourceA)
            try? FileManager.default.removeItem(at: sourceB)
            try? FileManager.default.removeItem(at: appSkills)
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        try makeSkillFolder(root: sourceA, folderName: "alpha")
        try makeSkillFolder(root: sourceA, folderName: "beta")
        try makeSkillFolder(root: sourceB, folderName: "gamma")

        let viewModel = makeViewModel(userDefaults: userDefaults, appSkillsPath: appSkills.path)
        viewModel.load()
        XCTAssertTrue(viewModel.addSource(path: sourceA.path))
        XCTAssertTrue(viewModel.addSource(path: sourceB.path))
        viewModel.syncSkills()

        XCTAssertEqual(viewModel.skills.count, 3)
        XCTAssertEqual(viewModel.sourceSkillCounts.count, 1)
        if let installedSourceID = viewModel.skills.first?.sourceID {
            XCTAssertEqual(viewModel.sourceSkillCounts[installedSourceID], 3)
        } else {
            XCTFail("missing installed skills")
        }
    }

    func testFilterStillWorksAfterSwitchingTabs() throws {
        let suiteName = "UITransformationTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)

        let sourceRoot = try makeTempDirectory()
        let appSkills = try makeTempDirectory()
        defer {
            try? FileManager.default.removeItem(at: sourceRoot)
            try? FileManager.default.removeItem(at: appSkills)
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        try makeSkillFolder(root: sourceRoot, folderName: "brainstorming")
        try makeSkillFolder(root: sourceRoot, folderName: "sqlite-helper")

        let viewModel = makeViewModel(userDefaults: userDefaults, appSkillsPath: appSkills.path)
        viewModel.load()
        XCTAssertTrue(viewModel.addSource(path: sourceRoot.path))
        viewModel.syncSkills()

        viewModel.selectTab(.sourceManagement)
        viewModel.selectTab(.appSkills)
        viewModel.searchText = "sqlite"

        XCTAssertEqual(viewModel.filteredSkills.count, 1)
        XCTAssertEqual(viewModel.filteredSkills.first?.folderName, "sqlite-helper")
    }

    func testAC_7_1_002AllAppTargetsExposeDisplayName() {
        let names = AppTarget.allCases.map(\.displayName)
        XCTAssertEqual(names.count, 9)
        XCTAssertEqual(
            names,
            ["Claude Code", "Codex", "OpenCode", "Trae", "Trae CN", "WorkBuddy", "CodeBuddy", "Aion UI", "Qoder"]
        )
    }

    private func makeTempDirectory() throws -> URL {
        let base = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let target = base.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        return target
    }

    private func makeSkillFolder(root: URL, folderName: String) throws {
        let folderURL = root.appendingPathComponent(folderName, isDirectory: true)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        let content = """
        ---
        name: \(folderName)
        description: test skill
        ---
        """
        try content.write(to: folderURL.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
    }

    private func makeViewModel(userDefaults: UserDefaults, appSkillsPath: String) -> MainViewModel {
        return MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: FileService(),
            appSkillsPathResolver: { _ in appSkillsPath },
            autoLoad: false
        )
    }
}
