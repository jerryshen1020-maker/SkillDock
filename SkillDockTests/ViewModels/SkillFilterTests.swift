import XCTest
@testable import SkillDock

@MainActor
final class SkillFilterTests: XCTestCase {
    func testFilterByKeywordMatchesNameOrDescription() throws {
        let suiteName = "SkillFilterTests-\(UUID().uuidString)"
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

        try makeSkillFolder(root: sourceRoot, folderName: "brainstorming", description: "design workflow")
        try makeSkillFolder(root: sourceRoot, folderName: "sqlite-helper", description: "database operations")

        let viewModel = makeViewModel(userDefaults: userDefaults, appSkillsPath: appSkills.path)
        viewModel.load()
        XCTAssertTrue(viewModel.addSource(path: sourceRoot.path))
        viewModel.syncSkills()
        XCTAssertEqual(viewModel.skills.count, 2)

        viewModel.searchText = "brain"
        XCTAssertEqual(viewModel.filteredSkills.count, 1)
        XCTAssertEqual(viewModel.filteredSkills.first?.folderName, "brainstorming")

        viewModel.searchText = "database"
        XCTAssertEqual(viewModel.filteredSkills.count, 1)
        XCTAssertEqual(viewModel.filteredSkills.first?.folderName, "sqlite-helper")
    }

    func testFilterBySourceAndKeywordUsesAndRelation() throws {
        let suiteName = "SkillFilterTests-\(UUID().uuidString)"
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

        try makeSkillFolder(root: sourceA, folderName: "brainstorming", description: "design workflow")
        try makeSkillFolder(root: sourceB, folderName: "brainstorming-cn", description: "design in chinese")

        let viewModel = makeViewModel(userDefaults: userDefaults, appSkillsPath: appSkills.path)
        viewModel.load()
        XCTAssertTrue(viewModel.addSource(path: sourceA.path))
        XCTAssertTrue(viewModel.addSource(path: sourceB.path))
        viewModel.syncSkills()
        XCTAssertEqual(viewModel.skills.count, 2)

        guard let sourceAID = viewModel.sources.first(where: { $0.path == sourceA.path })?.id else {
            XCTFail("missing source id")
            return
        }

        viewModel.searchText = "chinese"
        viewModel.selectedSourceFilterID = sourceAID

        XCTAssertTrue(viewModel.filteredSkills.isEmpty)
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

    private func makeViewModel(userDefaults: UserDefaults, appSkillsPath: String) -> MainViewModel {
        MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: FileService(),
            appSkillsPathResolver: { _ in appSkillsPath },
            autoLoad: false
        )
    }
}
