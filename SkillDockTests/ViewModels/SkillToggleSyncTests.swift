import XCTest
@testable import SkillDock

@MainActor
final class SkillToggleSyncTests: XCTestCase {
    func testToggleWritesPermissionsToClaudeSettings() throws {
        let suiteName = "SkillToggleSyncTests-\(UUID().uuidString)"
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

        let viewModel = MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: FileService(),
            autoLoad: false
        )
        viewModel.load()
        XCTAssertTrue(viewModel.addSource(path: sourceRoot.path))
        guard let skill = viewModel.skills.first else {
            XCTFail("missing skill")
            return
        }

        viewModel.setSkillEnabled(false, for: skill)
        XCTAssertFalse(viewModel.isSkillEnabled(skill))

        viewModel.setSkillEnabled(true, for: skill)
        XCTAssertTrue(viewModel.isSkillEnabled(skill))
    }

    func testSyncNormalizesLegacyLowercaseSkillsPrefix() throws {
        let projectRoot = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: projectRoot) }

        let settingsURL = projectRoot
            .appendingPathComponent(".claude", isDirectory: true)
            .appendingPathComponent("settings.json")
        try FileManager.default.createDirectory(
            at: settingsURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let legacy: [String: Any] = [
            "permissions": [
                "allow": ["skills:brainstorming", "Bash"],
                "deny": ["skills:backlog-manager"]
            ]
        ]
        let legacyData = try JSONSerialization.data(withJSONObject: legacy, options: [.prettyPrinted, .sortedKeys])
        try legacyData.write(to: settingsURL, options: .atomic)

        let skill = Skill(
            folderName: "brainstorming",
            name: "brainstorming",
            description: "desc",
            sourceID: UUID(),
            sourcePath: "/tmp/source",
            fullPath: "/tmp/source/brainstorming"
        )
        let configManager = ConfigManager()

        XCTAssertTrue(
            configManager.syncClaudePermissions(
                projectPath: projectRoot.path,
                skills: [skill],
                states: [skill.id: true]
            )
        )

        let permissions = try readPermissions(projectPath: projectRoot.path)
        XCTAssertTrue(permissions.allow.contains("Skills:brainstorming"))
        XCTAssertFalse(permissions.allow.contains("skills:brainstorming"))
        XCTAssertTrue(permissions.deny.contains("Skills:backlog-manager"))
        XCTAssertFalse(permissions.deny.contains("skills:backlog-manager"))
        XCTAssertTrue(permissions.allow.contains("Bash"))
    }

    private func readPermissions(projectPath: String) throws -> (allow: [String], deny: [String]) {
        let settingsPath = URL(fileURLWithPath: projectPath, isDirectory: true)
            .appendingPathComponent(".claude")
            .appendingPathComponent("settings.json")
            .path
        let data = try Data(contentsOf: URL(fileURLWithPath: settingsPath))
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let permissions = root["permissions"] as? [String: Any]
        else {
            XCTFail("invalid settings json structure")
            return ([], [])
        }
        let allow = permissions["allow"] as? [String] ?? []
        let deny = permissions["deny"] as? [String] ?? []
        return (allow, deny)
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
