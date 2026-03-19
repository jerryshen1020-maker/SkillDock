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
        let appSkills = try makeTempDirectory()
        defer {
            try? FileManager.default.removeItem(at: source)
            try? FileManager.default.removeItem(at: appSkills)
            userDefaults.removePersistentDomain(forName: suite)
        }

        try makeSkillFolder(root: source, folderName: "alpha", description: "a")
        let viewModel = makeViewModel(userDefaults: userDefaults, appSkillsPath: appSkills.path)
        viewModel.load()
        XCTAssertTrue(viewModel.addSource(path: source.path))
        XCTAssertEqual(viewModel.skills.count, 0)
        viewModel.syncSkills()
        XCTAssertEqual(Set(viewModel.skills.map(\.folderName)), Set(["alpha"]))

        try makeSkillFolder(root: source, folderName: "beta", description: "b")
        viewModel.syncSkills()

        XCTAssertNil(viewModel.pendingSyncPreview)
        XCTAssertEqual(Set(viewModel.skills.map(\.folderName)), Set(["alpha", "beta"]))
        XCTAssertTrue(viewModel.message?.hasPrefix("Sync completed: added 1, removed 0") == true)
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
        let appSkills = try makeTempDirectory()
        defer {
            try? FileManager.default.removeItem(at: sourceA)
            try? FileManager.default.removeItem(at: sourceB)
            try? FileManager.default.removeItem(at: appSkills)
            userDefaults.removePersistentDomain(forName: suite)
        }

        try makeSkillFolder(root: sourceA, folderName: "brainstorming", description: "a")
        let viewModel = makeViewModel(userDefaults: userDefaults, appSkillsPath: appSkills.path)
        viewModel.load()
        XCTAssertTrue(viewModel.addSource(path: sourceA.path))
        XCTAssertTrue(viewModel.addSource(path: sourceB.path))
        viewModel.syncSkills()

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
        let appSkills = try makeTempDirectory()
        defer {
            try? FileManager.default.removeItem(at: sourceA)
            try? FileManager.default.removeItem(at: sourceB)
            try? FileManager.default.removeItem(at: appSkills)
            userDefaults.removePersistentDomain(forName: suite)
        }

        try makeSkillFolder(root: sourceA, folderName: "brainstorming", description: "a")
        let viewModel = makeViewModel(userDefaults: userDefaults, appSkillsPath: appSkills.path)
        viewModel.load()
        XCTAssertTrue(viewModel.addSource(path: sourceA.path))
        XCTAssertTrue(viewModel.addSource(path: sourceB.path))
        viewModel.syncSkills()

        try makeSkillFolder(root: sourceB, folderName: "brainstorming", description: "b")
        viewModel.syncSkills()
        viewModel.resolvePendingSync(strategy: .keepExisting)

        XCTAssertNil(viewModel.pendingSyncPreview)
        let skills = viewModel.skills.filter { $0.folderName == "brainstorming" }
        XCTAssertEqual(skills.count, 1)
        XCTAssertEqual(skills.first?.description, "a")
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
        let appSkills = try makeTempDirectory()
        defer {
            try? FileManager.default.removeItem(at: sourceA)
            try? FileManager.default.removeItem(at: sourceB)
            try? FileManager.default.removeItem(at: appSkills)
            userDefaults.removePersistentDomain(forName: suite)
        }

        try makeSkillFolder(root: sourceA, folderName: "brainstorming", description: "a")
        let viewModel = makeViewModel(userDefaults: userDefaults, appSkillsPath: appSkills.path)
        viewModel.load()
        XCTAssertTrue(viewModel.addSource(path: sourceA.path))
        XCTAssertTrue(viewModel.addSource(path: sourceB.path))
        viewModel.syncSkills()

        try makeSkillFolder(root: sourceB, folderName: "brainstorming", description: "b")
        viewModel.syncSkills()
        viewModel.resolvePendingSync(strategy: .replaceWithIncoming)

        XCTAssertNil(viewModel.pendingSyncPreview)
        let skills = viewModel.skills.filter { $0.folderName == "brainstorming" }
        XCTAssertEqual(skills.count, 1)
        XCTAssertTrue(["a", "b"].contains(skills.first?.description ?? ""))
    }

    func testAC_7_5_001SyncFailureKeepsDiagnosticsMessage() throws {
        let suite = "SyncFlowTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suite) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suite)

        let source = try makeTempDirectory()
        let appSkills = try makeTempDirectory()
        defer {
            try? FileManager.default.removeItem(at: source)
            try? FileManager.default.removeItem(at: appSkills)
            userDefaults.removePersistentDomain(forName: suite)
        }

        try makeSkillFolder(root: source, folderName: "alpha", description: "a")
        let viewModel = makeViewModel(userDefaults: userDefaults, appSkillsPath: appSkills.path)
        viewModel.load()
        XCTAssertTrue(viewModel.addSource(path: source.path))
        try FileManager.default.removeItem(at: source)

        viewModel.syncSkills()

        XCTAssertTrue(viewModel.message?.contains("Failed to scan") == true)
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
