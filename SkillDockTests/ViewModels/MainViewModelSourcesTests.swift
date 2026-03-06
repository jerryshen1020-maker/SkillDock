import XCTest
@testable import SkillDock

@MainActor
final class MainViewModelSourcesTests: XCTestCase {
    func testLoadRestoresThemeModeFromConfig() throws {
        let suiteName = "MainViewModelSourcesTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let config = AppConfig(
            sources: [],
            selectedApp: .claudeCode,
            selectedPage: .settings,
            themeMode: .dark,
            legacySkillStates: [:]
        )
        ConfigManager(userDefaults: userDefaults).saveAppConfig(config)

        let viewModel = MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: FileService(),
            autoLoad: false
        )
        viewModel.load()

        XCTAssertEqual(viewModel.themeMode, .dark)
    }

    func testSetThemeModePersistsToConfig() throws {
        let suiteName = "MainViewModelSourcesTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let viewModel = MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: FileService(),
            autoLoad: false
        )
        viewModel.load()

        viewModel.setThemeMode(.dark)

        XCTAssertEqual(viewModel.themeMode, .dark)
        let persisted = ConfigManager(userDefaults: userDefaults).loadAppConfig()
        XCTAssertEqual(persisted.themeMode, .dark)
    }

    func testLoadRestoresSelectedAppFromConfig() throws {
        let suiteName = "MainViewModelSourcesTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let config = AppConfig(
            sources: [],
            selectedApp: .openCode,
            selectedPage: .skills,
            themeMode: .system,
            legacySkillStates: [:]
        )
        ConfigManager(userDefaults: userDefaults).saveAppConfig(config)

        let viewModel = MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: FileService(),
            autoLoad: false
        )

        viewModel.load()

        XCTAssertEqual(viewModel.selectedApp, .openCode)
    }

    func testSelectAppUpdatesBuiltInSourceAndPersists() throws {
        let suiteName = "MainViewModelSourcesTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)

        let codexPath = ("~/.codex/skills/" as NSString).expandingTildeInPath
        let fileManager = FileManager.default
        let alreadyExists = fileManager.fileExists(atPath: codexPath)
        if !alreadyExists {
            try fileManager.createDirectory(
                at: URL(fileURLWithPath: codexPath, isDirectory: true),
                withIntermediateDirectories: true
            )
        }
        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
            if !alreadyExists {
                try? fileManager.removeItem(atPath: codexPath)
            }
        }

        let viewModel = MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: FileService(),
            autoLoad: false
        )
        viewModel.load()

        viewModel.selectApp(.codex)

        XCTAssertEqual(viewModel.selectedApp, .codex)
        let builtIn = viewModel.sources.first {
            $0.isBuiltIn && ($0.path as NSString).expandingTildeInPath == codexPath
        }
        XCTAssertNotNil(builtIn)
        let persisted = ConfigManager(userDefaults: userDefaults).loadAppConfig()
        XCTAssertEqual(persisted.selectedApp, .codex)
    }

    func testAC_7_1_001SelectAppUpdatesSelectedAppName() throws {
        let suiteName = "MainViewModelSourcesTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let viewModel = MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: FileService(),
            autoLoad: false
        )
        viewModel.load()

        viewModel.selectApp(.traeCN)

        XCTAssertEqual(viewModel.selectedAppName, "Trae CN")
        XCTAssertEqual(viewModel.selectedApp, .traeCN)
        XCTAssertEqual(viewModel.message, "已切换应用：Trae CN")
    }

    func testAC_7_4_001SetThemeModePersistsAndShowsFeedback() throws {
        let suiteName = "MainViewModelSourcesTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let viewModel = MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: FileService(),
            autoLoad: false
        )
        viewModel.load()

        viewModel.setThemeMode(.light)

        XCTAssertEqual(viewModel.themeMode, .light)
        XCTAssertEqual(viewModel.message, "主题已切换为浅色")
        XCTAssertEqual(ConfigManager(userDefaults: userDefaults).loadAppConfig().themeMode, .light)
    }

    func testSyncSkillsCreatesSymlinkInSelectedAppDirectory() throws {
        let suiteName = "MainViewModelSourcesTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)

        let sourceRoot = try makeTempDirectory()
        let targetRootURL = try makeTempDirectory()
        let folderName = "sync-link-\(UUID().uuidString)"
        try makeSkillFolder(root: sourceRoot, folderName: folderName)
        let skillFolderPath = sourceRoot.appendingPathComponent(folderName, isDirectory: true).path
        let targetPath = targetRootURL
            .appendingPathComponent(folderName, isDirectory: true)
            .path

        defer {
            try? FileManager.default.removeItem(at: sourceRoot)
            try? FileManager.default.removeItem(at: targetRootURL)
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let viewModel = MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: FileService(),
            appSkillsPathResolver: { _ in targetRootURL.path },
            autoLoad: false
        )
        viewModel.load()
        viewModel.selectApp(.codex)
        XCTAssertTrue(viewModel.addSource(path: sourceRoot.path))

        viewModel.syncSkills()

        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        XCTAssertTrue(fileManager.fileExists(atPath: targetPath, isDirectory: &isDirectory))
        let attributes = try fileManager.attributesOfItem(atPath: targetPath)
        let fileType = attributes[.type] as? FileAttributeType
        XCTAssertEqual(fileType, .typeSymbolicLink)
        let linkedPath = try fileManager.destinationOfSymbolicLink(atPath: targetPath)
        XCTAssertEqual(URL(fileURLWithPath: linkedPath).standardizedFileURL.path, URL(fileURLWithPath: skillFolderPath).standardizedFileURL.path)
    }

    func testSyncSkillsSkipsNonSymlinkConflictAndContinues() throws {
        let suiteName = "MainViewModelSourcesTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)

        let sourceRoot = try makeTempDirectory()
        let targetRootURL = try makeTempDirectory()
        let conflictFolder = "conflict-\(UUID().uuidString)"
        let normalFolder = "normal-\(UUID().uuidString)"
        try makeSkillFolder(root: sourceRoot, folderName: conflictFolder)
        try makeSkillFolder(root: sourceRoot, folderName: normalFolder)
        let conflictTargetURL = targetRootURL.appendingPathComponent(conflictFolder, isDirectory: true)
        try FileManager.default.createDirectory(at: conflictTargetURL, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: sourceRoot)
            try? FileManager.default.removeItem(at: targetRootURL)
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let viewModel = MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: FileService(),
            appSkillsPathResolver: { _ in targetRootURL.path },
            autoLoad: false
        )
        viewModel.load()
        viewModel.selectApp(.codex)
        XCTAssertTrue(viewModel.addSource(path: sourceRoot.path))

        viewModel.syncSkills()

        let fileManager = FileManager.default
        let normalTargetPath = targetRootURL.appendingPathComponent(normalFolder, isDirectory: true).path
        let normalType = try fileManager.attributesOfItem(atPath: normalTargetPath)[.type] as? FileAttributeType
        XCTAssertEqual(normalType, .typeSymbolicLink)
        let conflictType = try fileManager.attributesOfItem(atPath: conflictTargetURL.path)[.type] as? FileAttributeType
        XCTAssertEqual(conflictType, .typeDirectory)
        XCTAssertTrue(viewModel.message?.contains("跳过 1 个冲突项") == true)
        XCTAssertEqual(viewModel.latestSyncDiagnostics?.skippedFolderNames.count, 1)
        XCTAssertEqual(viewModel.latestSyncDiagnostics?.fatalError, nil)
    }

    func testAddSourceScansSkillsAndPersistsSource() throws {
        let suiteName = "MainViewModelSourcesTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)

        let tempRoot = try makeTempDirectory()
        defer {
            try? FileManager.default.removeItem(at: tempRoot)
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        try makeSkillFolder(root: tempRoot, folderName: "brainstorming")

        let viewModel = MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: FileService(),
            autoLoad: false
        )
        viewModel.load()
        let initialSourceCount = viewModel.sources.count
        let initialSkills = viewModel.skills

        let added = viewModel.addSource(path: tempRoot.path)

        XCTAssertTrue(added)
        XCTAssertEqual(viewModel.sources.count, initialSourceCount + 1)
        XCTAssertTrue(viewModel.sources.contains { $0.path == tempRoot.path })
        XCTAssertEqual(viewModel.skills, initialSkills)
        XCTAssertTrue(
            ConfigManager(userDefaults: userDefaults)
                .loadAppConfig()
                .sources
                .contains { $0.path == tempRoot.path }
        )
    }

    func testAddSourceRejectsDuplicate() throws {
        let suiteName = "MainViewModelSourcesTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)

        let tempRoot = try makeTempDirectory()
        defer {
            try? FileManager.default.removeItem(at: tempRoot)
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let viewModel = MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: FileService(),
            autoLoad: false
        )
        viewModel.load()
        let initialSourceCount = viewModel.sources.count

        XCTAssertTrue(viewModel.addSource(path: tempRoot.path))
        XCTAssertFalse(viewModel.addSource(path: tempRoot.path))
        XCTAssertEqual(viewModel.sources.count, initialSourceCount + 1)
    }

    func testRemoveSourceUpdatesSkills() throws {
        let suiteName = "MainViewModelSourcesTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)

        let tempRoot = try makeTempDirectory()
        defer {
            try? FileManager.default.removeItem(at: tempRoot)
            userDefaults.removePersistentDomain(forName: suiteName)
        }
        try makeSkillFolder(root: tempRoot, folderName: "writing-assistant")

        let viewModel = MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: FileService(),
            autoLoad: false
        )
        viewModel.load()
        let initialSkills = viewModel.skills
        XCTAssertTrue(viewModel.addSource(path: tempRoot.path))
        XCTAssertEqual(viewModel.skills, initialSkills)

        guard let source = viewModel.sources.first(where: { $0.path == tempRoot.path }) else {
            XCTFail("missing source")
            return
        }
        viewModel.removeSource(source)

        XCTAssertFalse(viewModel.sources.contains { $0.path == tempRoot.path })
        XCTAssertEqual(viewModel.skills, initialSkills)
    }

    func testRemoveBuiltInSourceIsBlocked() throws {
        let suiteName = "MainViewModelSourcesTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)

        let tempRoot = try makeTempDirectory()
        defer {
            try? FileManager.default.removeItem(at: tempRoot)
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let builtInSource = Source(path: tempRoot.path, displayName: "全局 Skills", isBuiltIn: true)
        let config = AppConfig(sources: [builtInSource], legacySkillStates: [:])
        ConfigManager(userDefaults: userDefaults).saveAppConfig(config)

        let viewModel = MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: FileService(),
            autoLoad: false
        )
        viewModel.load()
        guard let source = viewModel.sources.first(where: { $0.isBuiltIn }) else {
            XCTFail("missing source")
            return
        }

        viewModel.removeSource(source)

        XCTAssertTrue(viewModel.sources.contains { $0.isBuiltIn })
    }

    func testLoadAddsDefaultBuiltInSourceWhenDirectoryExists() throws {
        let suiteName = "MainViewModelSourcesTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)

        let defaultPath = ("~/.claude/skills/" as NSString).expandingTildeInPath
        let fileManager = FileManager.default
        let alreadyExists = fileManager.fileExists(atPath: defaultPath)
        if !alreadyExists {
            try fileManager.createDirectory(
                at: URL(fileURLWithPath: defaultPath, isDirectory: true),
                withIntermediateDirectories: true
            )
        }
        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
            if !alreadyExists {
                try? fileManager.removeItem(atPath: defaultPath)
            }
        }

        let viewModel = MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: FileService(),
            autoLoad: false
        )
        viewModel.load()

        let builtIn = viewModel.sources.first {
            $0.isBuiltIn && ($0.path as NSString).expandingTildeInPath == defaultPath
        }
        XCTAssertNotNil(builtIn)
    }

    func testAddGitSourceCloneFailurePersistsUnavailableSource() throws {
        let suiteName = "MainViewModelSourcesTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let gitService = FakeGitService(
            cloneResult: .failure(GitServiceError(message: "network down")),
            pullResult: .success(())
        )
        let viewModel = MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: FileService(),
            gitService: gitService,
            autoLoad: false
        )
        viewModel.load()

        let added = viewModel.addGitSource(repoURL: "https://example.com/repo.git", branch: "main")

        XCTAssertFalse(added)
        XCTAssertEqual(gitService.clonedRepoURLs, ["https://example.com/repo.git"])
        let source = viewModel.sources.first { $0.type == .git && $0.repoURL == "https://example.com/repo.git" }
        XCTAssertNotNil(source)
        XCTAssertEqual(source?.isAvailable, false)
        XCTAssertNotNil(source?.lastError)
    }

    func testUpdateGitSourceSuccessClearsErrorAndMarksAvailable() throws {
        let suiteName = "MainViewModelSourcesTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)

        let tempRoot = try makeTempDirectory()
        defer {
            try? FileManager.default.removeItem(at: tempRoot)
            userDefaults.removePersistentDomain(forName: suiteName)
        }
        let source = Source(
            path: tempRoot.path,
            displayName: "repo",
            type: .git,
            repoURL: "https://example.com/repo.git",
            branch: "main",
            isAvailable: false,
            lastError: "old error"
        )
        ConfigManager(userDefaults: userDefaults).saveAppConfig(AppConfig(sources: [source]))

        let gitService = FakeGitService(
            cloneResult: .success(()),
            pullResult: .success(())
        )
        let viewModel = MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: FileService(),
            gitService: gitService,
            autoLoad: false
        )
        viewModel.load()
        guard let target = viewModel.sources.first else {
            XCTFail("missing source")
            return
        }

        let updated = viewModel.updateGitSource(target)

        XCTAssertTrue(updated)
        XCTAssertEqual(gitService.pulledLocalPaths, [tempRoot.path])
        guard let refreshed = viewModel.sources.first(where: { $0.id == target.id }) else {
            XCTFail("source not found after update")
            return
        }
        XCTAssertTrue(refreshed.isAvailable)
        XCTAssertNil(refreshed.lastError)
    }

    func testRetryLocalSourceKeepsUnavailableWhenPathMissing() throws {
        let suiteName = "MainViewModelSourcesTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let missingPath = "/tmp/not-exists-\(UUID().uuidString)"
        let source = Source(
            path: missingPath,
            displayName: "missing",
            type: .local,
            isAvailable: false,
            lastError: "目录不存在"
        )
        ConfigManager(userDefaults: userDefaults).saveAppConfig(AppConfig(sources: [source]))
        let viewModel = MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: FileService(),
            autoLoad: false
        )
        viewModel.load()
        guard let target = viewModel.sources.first else {
            XCTFail("missing source")
            return
        }

        viewModel.retrySource(target)

        guard let refreshed = viewModel.sources.first(where: { $0.id == target.id }) else {
            XCTFail("source not found after retry")
            return
        }
        XCTAssertFalse(refreshed.isAvailable)
        XCTAssertEqual(refreshed.lastError, "目录不存在")
    }

    func testExportSyncDiagnosticsShowsPermissionDeniedMessage() throws {
        let suiteName = "MainViewModelSourcesTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)

        let sourceRoot = try makeTempDirectory()
        let targetRootURL = try makeTempDirectory()
        let conflictFolder = "permission-\(UUID().uuidString)"
        try makeSkillFolder(root: sourceRoot, folderName: conflictFolder)
        let conflictTargetURL = targetRootURL.appendingPathComponent(conflictFolder, isDirectory: true)
        try FileManager.default.createDirectory(at: conflictTargetURL, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: sourceRoot)
            try? FileManager.default.removeItem(at: targetRootURL)
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let fileService = FakeFileService(exportResult: .permissionDenied)
        let viewModel = MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: fileService,
            appSkillsPathResolver: { _ in targetRootURL.path },
            autoLoad: false
        )
        viewModel.load()
        viewModel.selectApp(.codex)
        XCTAssertTrue(viewModel.addSource(path: sourceRoot.path))
        viewModel.syncSkills()

        viewModel.exportLatestSyncDiagnostics()

        XCTAssertEqual(viewModel.message, "哎呀，没有写入权限，请选择其他目录")
    }

    func testExportSyncDiagnosticsShowsWriteFailureMessage() throws {
        let suiteName = "MainViewModelSourcesTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("unable to create user defaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)

        let sourceRoot = try makeTempDirectory()
        let targetRootURL = try makeTempDirectory()
        let conflictFolder = "write-\(UUID().uuidString)"
        try makeSkillFolder(root: sourceRoot, folderName: conflictFolder)
        let conflictTargetURL = targetRootURL.appendingPathComponent(conflictFolder, isDirectory: true)
        try FileManager.default.createDirectory(at: conflictTargetURL, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: sourceRoot)
            try? FileManager.default.removeItem(at: targetRootURL)
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let fileService = FakeFileService(exportResult: .writeFailed)
        let viewModel = MainViewModel(
            configManager: ConfigManager(userDefaults: userDefaults),
            skillScanner: SkillScanner(),
            fileService: fileService,
            appSkillsPathResolver: { _ in targetRootURL.path },
            autoLoad: false
        )
        viewModel.load()
        viewModel.selectApp(.codex)
        XCTAssertTrue(viewModel.addSource(path: sourceRoot.path))
        viewModel.syncSkills()

        viewModel.exportLatestSyncDiagnostics()

        XCTAssertEqual(viewModel.message, "哎呀，写入失败，请稍后重试")
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

private final class FakeGitService: GitServiceType {
    private let cloneResult: Result<Void, Error>
    private let pullResult: Result<Void, Error>
    private(set) var clonedRepoURLs: [String] = []
    private(set) var pulledLocalPaths: [String] = []

    init(cloneResult: Result<Void, Error>, pullResult: Result<Void, Error>) {
        self.cloneResult = cloneResult
        self.pullResult = pullResult
    }

    func clone(repoURL: String, branch: String?, to localPath: String) -> Result<Void, Error> {
        clonedRepoURLs.append(repoURL)
        return cloneResult
    }

    func pull(localPath: String, branch: String?) -> Result<Void, Error> {
        pulledLocalPaths.append(localPath)
        return pullResult
    }
}

private final class FakeFileService: FileServiceType {
    private let exportResult: TextExportResult

    init(exportResult: TextExportResult) {
        self.exportResult = exportResult
    }

    func directoryExists(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    func copyTextToClipboard(_ text: String) -> Bool {
        true
    }

    func saveTextWithPanel(defaultFileName: String, content: String) -> TextExportResult {
        exportResult
    }

    func revealInFinder(_ path: String) {}

    func pickDirectory() -> String? {
        nil
    }
}
