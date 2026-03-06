import XCTest
@testable import SkillDock

@MainActor
final class SyncFlowTests: XCTestCase {
    func testSyncWithoutConflictUpdatesSkillList() throws {
        let suite = "SyncFlowTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suite) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suite)

        let source = try makeTempDirectory()
        defer {
            try? FileManager.default.removeItem(at: source)
            userDefaults.removePersistentDomain(forName: suite)
        }

        try makeSkillFolder(root: source, folderName: "alpha", description: "a")
        let viewModel = makeViewModel(userDefaults: userDefaults)
        viewModel.load()
        XCTAssertTrue(viewModel.addSource(path: source.path))
        XCTAssertEqual(viewModel.skills.map(\.folderName), ["alpha"])

        try makeSkillFolder(root: source, folderName: "beta", description: "b")
        viewModel.syncSkills()

        XCTAssertNil(viewModel.pendingSyncPreview)
        XCTAssertEqual(Set(viewModel.skills.map(\.folderName)), Set(["alpha", "beta"]))
        XCTAssertTrue(viewModel.message?.hasPrefix("同步完成：新增 1 个，移除 0 个") == true)
    }

    func testSyncDetectsFolderNameConflictsAcrossSources() throws {
        let suite = "SyncFlowTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suite) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suite)

        let sourceA = try makeTempDirectory()
        let sourceB = try makeTempDirectory()
        defer {
            try? FileManager.default.removeItem(at: sourceA)
            try? FileManager.default.removeItem(at: sourceB)
            userDefaults.removePersistentDomain(forName: suite)
        }

        try makeSkillFolder(root: sourceA, folderName: "brainstorming", description: "a")
        let viewModel = makeViewModel(userDefaults: userDefaults)
        viewModel.load()
        XCTAssertTrue(viewModel.addSource(path: sourceA.path))
        XCTAssertTrue(viewModel.addSource(path: sourceB.path))

        try makeSkillFolder(root: sourceB, folderName: "brainstorming", description: "b")
        viewModel.syncSkills()

        XCTAssertNotNil(viewModel.pendingSyncPreview)
        XCTAssertEqual(viewModel.pendingSyncPreview?.conflicts.count, 1)
    }

    func testResolveConflictKeepExistingKeepsOldSkill() throws {
        let suite = "SyncFlowTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suite) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suite)

        let sourceA = try makeTempDirectory()
        let sourceB = try makeTempDirectory()
        defer {
            try? FileManager.default.removeItem(at: sourceA)
            try? FileManager.default.removeItem(at: sourceB)
            userDefaults.removePersistentDomain(forName: suite)
        }

        try makeSkillFolder(root: sourceA, folderName: "brainstorming", description: "a")
        let viewModel = makeViewModel(userDefaults: userDefaults)
        viewModel.load()
        XCTAssertTrue(viewModel.addSource(path: sourceA.path))
        XCTAssertTrue(viewModel.addSource(path: sourceB.path))

        try makeSkillFolder(root: sourceB, folderName: "brainstorming", description: "b")
        viewModel.syncSkills()
        viewModel.resolvePendingSync(strategy: .keepExisting)

        XCTAssertNil(viewModel.pendingSyncPreview)
        XCTAssertEqual(viewModel.skills.filter { $0.folderName == "brainstorming" }.count, 1)
        XCTAssertTrue(viewModel.skills.contains { $0.sourcePath == sourceA.path && $0.folderName == "brainstorming" })
    }

    func testResolveConflictReplaceWithIncomingKeepsNewSkills() throws {
        let suite = "SyncFlowTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suite) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suite)

        let sourceA = try makeTempDirectory()
        let sourceB = try makeTempDirectory()
        defer {
            try? FileManager.default.removeItem(at: sourceA)
            try? FileManager.default.removeItem(at: sourceB)
            userDefaults.removePersistentDomain(forName: suite)
        }

        try makeSkillFolder(root: sourceA, folderName: "brainstorming", description: "a")
        let viewModel = makeViewModel(userDefaults: userDefaults)
        viewModel.load()
        XCTAssertTrue(viewModel.addSource(path: sourceA.path))
        XCTAssertTrue(viewModel.addSource(path: sourceB.path))

        try makeSkillFolder(root: sourceB, folderName: "brainstorming", description: "b")
        viewModel.syncSkills()
        viewModel.resolvePendingSync(strategy: .replaceWithIncoming)

        XCTAssertNil(viewModel.pendingSyncPreview)
        XCTAssertEqual(viewModel.skills.filter { $0.folderName == "brainstorming" }.count, 2)
        XCTAssertTrue(viewModel.skills.contains { $0.sourcePath == sourceA.path && $0.folderName == "brainstorming" })
        XCTAssertTrue(viewModel.skills.contains { $0.sourcePath == sourceB.path && $0.folderName == "brainstorming" })
    }

    func testAC_7_5_001SyncFailureKeepsDiagnosticsMessage() throws {
        let suite = "SyncFlowTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suite) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suite)

        let source = try makeTempDirectory()
        defer {
            try? FileManager.default.removeItem(at: source)
            userDefaults.removePersistentDomain(forName: suite)
        }

        try makeSkillFolder(root: source, folderName: "alpha", description: "a")
        let viewModel = makeViewModel(userDefaults: userDefaults)
        viewModel.load()
        XCTAssertTrue(viewModel.addSource(path: source.path))
        try FileManager.default.removeItem(at: source)

        viewModel.syncSkills()

        XCTAssertTrue(viewModel.message?.contains("扫描失败") == true)
    }

    private func makeViewModel(userDefaults: UserDefaults) -> MainViewModel {
        MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: FileService(),
            autoLoad: false
        )
    }

    private func makeTempDirectory() throws -> URL {
        let base = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let target = base.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        return target
    }

    private func makeSkillFolder(root: URL, folderName: String, description: String) throws {
        let folderURL = root.appendingPathComponent(folderName, isDirectory: true)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        let content = """
        ---
        name: \(folderName)
        description: \(description)
        ---
        """
        try content.write(to: folderURL.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
    }
}
