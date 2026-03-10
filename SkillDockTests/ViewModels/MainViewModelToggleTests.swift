import XCTest
@testable import SkillDock

@MainActor
final class MainViewModelToggleTests: XCTestCase {
    func testTogglePersistsGlobalSkillState() throws {
        let suiteName = "MainViewModelToggleTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)

        let tempRoot = try makeTempDirectory()
        let appSkills = try makeTempDirectory()
        defer {
            try? FileManager.default.removeItem(at: tempRoot)
            try? FileManager.default.removeItem(at: appSkills)
            userDefaults.removePersistentDomain(forName: suiteName)
        }
        try makeSkillFolder(root: tempRoot, folderName: "brainstorming")

        let viewModel = makeViewModel(userDefaults: userDefaults, appSkillsPath: appSkills.path)
        viewModel.load()
        XCTAssertTrue(viewModel.addSource(path: tempRoot.path))
        viewModel.syncSkills()
        guard let skill = viewModel.skills.first else {
            XCTFail("missing skill")
            return
        }

        viewModel.setSkillEnabled(false, for: skill)
        XCTAssertFalse(viewModel.isSkillEnabled(skill))

        let persisted = ConfigManager(userDefaults: userDefaults).loadAppConfig()
        XCTAssertEqual(persisted.skillStates[skill.id], false)
    }

    func testLoadRestoresGlobalSkillStates() throws {
        let suiteName = "MainViewModelToggleTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)

        let tempRoot = try makeTempDirectory()
        let appSkills = try makeTempDirectory()
        defer {
            try? FileManager.default.removeItem(at: tempRoot)
            try? FileManager.default.removeItem(at: appSkills)
            userDefaults.removePersistentDomain(forName: suiteName)
        }
        try makeSkillFolder(root: tempRoot, folderName: "brainstorming")

        let source = Source(path: tempRoot.path, displayName: "skills")
        var candidatePaths = Set<String>()
        candidatePaths.insert(tempRoot.path)
        candidatePaths.insert(tempRoot.standardizedFileURL.path)
        candidatePaths.insert(tempRoot.resolvingSymlinksInPath().path)
        if tempRoot.path.hasPrefix("/var/") {
            candidatePaths.insert("/private" + tempRoot.path)
        }
        if tempRoot.path.hasPrefix("/private/var/") {
            let stripped = String(tempRoot.path.dropFirst("/private".count))
            candidatePaths.insert(stripped)
        }
        let seededStates = Dictionary(
            uniqueKeysWithValues: candidatePaths.map {
                (Skill.makeID(sourcePath: $0, folderName: "brainstorming"), false)
            }
        )
        let seeded = AppConfig(
            sources: [source],
            legacySkillStates: seededStates
        )
        ConfigManager(userDefaults: userDefaults).saveAppConfig(seeded)

        let viewModel = makeViewModel(userDefaults: userDefaults, appSkillsPath: appSkills.path)
        viewModel.load()
        viewModel.syncSkills()

        XCTAssertEqual(viewModel.skills.count, 1)
        let persisted = ConfigManager(userDefaults: userDefaults).loadAppConfig()
        XCTAssertTrue(persisted.skillStates.values.contains(false))
    }

    private func makeViewModel(userDefaults: UserDefaults, appSkillsPath: String) -> MainViewModel {
        MainViewModel(
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
