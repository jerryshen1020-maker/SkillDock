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
        defer {
            try? FileManager.default.removeItem(at: sourceA)
            try? FileManager.default.removeItem(at: sourceB)
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        try makeSkillFolder(root: sourceA, folderName: "alpha")
        try makeSkillFolder(root: sourceA, folderName: "beta")
        try makeSkillFolder(root: sourceB, folderName: "gamma")

        let viewModel = MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: FileService(),
            autoLoad: false
        )
        viewModel.load()
        XCTAssertTrue(viewModel.addSource(path: sourceA.path))
        XCTAssertTrue(viewModel.addSource(path: sourceB.path))

        let sourceAID = viewModel.sources.first(where: { $0.path == sourceA.path })?.id
        let sourceBID = viewModel.sources.first(where: { $0.path == sourceB.path })?.id

        XCTAssertEqual(viewModel.skills.count, 3)
        XCTAssertEqual(viewModel.sourceSkillCounts[sourceAID ?? UUID()], 2)
        XCTAssertEqual(viewModel.sourceSkillCounts[sourceBID ?? UUID()], 1)
    }

    func testFilterStillWorksAfterSwitchingTabs() throws {
        let suiteName = "UITransformationTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)

        let sourceRoot = try makeTempDirectory()
        defer {
            try? FileManager.default.removeItem(at: sourceRoot)
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        try makeSkillFolder(root: sourceRoot, folderName: "brainstorming")
        try makeSkillFolder(root: sourceRoot, folderName: "sqlite-helper")

        let viewModel = MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: FileService(),
            autoLoad: false
        )
        viewModel.load()
        XCTAssertTrue(viewModel.addSource(path: sourceRoot.path))

        viewModel.selectTab(.sourceManagement)
        viewModel.selectTab(.appSkills)
        viewModel.searchText = "sqlite"

        XCTAssertEqual(viewModel.filteredSkills.count, 1)
        XCTAssertEqual(viewModel.filteredSkills.first?.folderName, "sqlite-helper")
    }

    func testAC_7_1_002AllAppTargetsExposeDisplayName() {
        let names = AppTarget.allCases.map(\.displayName)
        XCTAssertEqual(names.count, 5)
        XCTAssertEqual(names, ["Claude Code", "Codex", "OpenCode", "Trae", "Trae CN"])
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
}
