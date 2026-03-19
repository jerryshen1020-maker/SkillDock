import Foundation

enum SidebarTab: String, CaseIterable, Identifiable {
    case appSkills = "App Skills"
    case sourceManagement = "来源管理"
    case settings = "设置"

    var id: String { rawValue }
}

enum ConflictResolutionStrategy: String, CaseIterable, Identifiable {
    case keepExisting
    case replaceWithIncoming
    case keepAllExisting
    case keepAllIncoming

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keepExisting: return "保留旧的"
        case .replaceWithIncoming: return "替换为新的"
        case .keepAllExisting: return "全部保留旧的"
        case .keepAllIncoming: return "全部用新的"
        }
    }
}

struct SyncConflict: Identifiable {
    let folderName: String
    let existing: [Skill]
    let incoming: [Skill]

    var id: String { folderName }
}

struct SyncPreview {
    let incomingSkills: [Skill]
    let addedCount: Int
    let removedCount: Int
    let conflicts: [SyncConflict]
}

struct SyncDiagnostics {
    let app: AppTarget
    let targetPath: String
    let skippedFolderNames: [String]
    let warnings: [String]
    let fatalError: String?

    init(
        app: AppTarget = .claudeCode,
        targetPath: String = "",
        skippedFolderNames: [String],
        warnings: [String],
        fatalError: String?
    ) {
        self.app = app
        self.targetPath = targetPath
        self.skippedFolderNames = skippedFolderNames
        self.warnings = warnings
        self.fatalError = fatalError
    }

    var hasIssues: Bool {
        fatalError != nil || !skippedFolderNames.isEmpty || !warnings.isEmpty
    }

    func summaryMessage(prefersChinese: Bool) -> String? {
        if let fatalError {
            return fatalError
        }
        guard hasIssues else {
            return nil
        }
        var summary: [String] = []
        if !skippedFolderNames.isEmpty {
            summary.append(prefersChinese ? "跳过 \(skippedFolderNames.count) 个冲突项" : "Skipped \(skippedFolderNames.count) conflict items")
        }
        if !warnings.isEmpty {
            summary.append(contentsOf: warnings)
        }
        return summary.joined(separator: prefersChinese ? "，" : ", ")
    }
}

@MainActor
final class MainViewModel: ObservableObject {
    @Published var selectedTab: SidebarTab = .appSkills
    @Published private(set) var selectedApp: AppTarget = .claudeCode
    @Published private(set) var themeMode: ThemeMode = .system
    @Published private(set) var skillViewMode: SkillViewMode = .installedOnly
    @Published private(set) var language: Language = .english
    @Published private(set) var sources: [Source] = []
    @Published private(set) var skills: [Skill] = []
    @Published private(set) var repositorySkills: [Skill] = []
    @Published var sourceInputPath: String = ""
    @Published var gitRepoInput: String = ""
    @Published var gitBranchInput: String = "main"
    @Published var searchText: String = ""
    @Published var selectedSourceFilterID: UUID?
    @Published private(set) var pendingSyncPreview: SyncPreview?
    @Published private(set) var latestSyncDiagnostics: SyncDiagnostics?
    @Published private(set) var isLoadingInstalledSkills: Bool = false
    @Published private(set) var isLoadingRepositorySkills: Bool = false
    @Published private(set) var isSyncing: Bool = false
    @Published private(set) var activeGitSourceIDs: Set<UUID> = []
    @Published private(set) var gitProgressMessage: String?
    @Published var message: String?

    private let configManager: ConfigManager
    private let skillScanner: SkillScanner
    private let fileService: FileServiceType
    private let gitService: GitServiceType
    private let appSkillsPathResolver: (AppTarget) -> String
    private var globalSkillStates: [String: Bool] = [:]
    private var hasLoaded = false

    init(
        configManager: ConfigManager = ConfigManager(),
        skillScanner: SkillScanner = SkillScanner(),
        fileService: FileServiceType = FileService(),
        gitService: GitServiceType = GitService(),
        appSkillsPathResolver: @escaping (AppTarget) -> String = { $0.defaultSkillsPath },
        autoLoad: Bool = true
    ) {
        self.configManager = configManager
        self.skillScanner = skillScanner
        self.fileService = fileService
        self.gitService = gitService
        self.appSkillsPathResolver = appSkillsPathResolver
        if autoLoad {
            load()
        }
    }

    func load() {
        guard !hasLoaded else { return }
        let config = configManager.loadAppConfig()
        selectedApp = config.selectedApp
        themeMode = config.themeMode
        skillViewMode = config.skillViewMode
        language = config.language
        selectedTab = sidebarTab(for: config.selectedPage)
        sources = config.sources
        globalSkillStates = config.skillStates
        ensureDefaultSource()
        refreshSkills()
        hasLoaded = true
    }

    func applyUITestOverridesIfNeeded(processInfo: ProcessInfo = .processInfo) {
        let arguments = Set(processInfo.arguments)
        guard arguments.contains("-uitest_mode") else { return }
        language = .english
        if arguments.contains("-uitest_visual_snapshot") {
            selectedApp = .claudeCode
            selectedTab = .appSkills
            searchText = ""
            selectedSourceFilterID = nil
            message = nil
            latestSyncDiagnostics = nil
            themeMode = .light
            sources.removeAll { !$0.isBuiltIn }
            ensureDefaultSource()
            refreshInstalledSkills()
        }
        if arguments.contains("-uitest_force_chinese") {
            language = .chinese
        }
        if arguments.contains("-uitest_seed_toast_warning") {
            Task { @MainActor in
                self.message = self.localized(
                    key: "git.batch.none",
                    chinese: "暂无 Git 来源可更新",
                    english: "No Git sources available to update"
                )
            }
        }
        if arguments.contains("-uitest_seed_unavailable_source") {
            let seededSource = Source(
                path: "/tmp/skilldock-uitest-unavailable-source",
                displayName: "UI Test Unavailable",
                type: .local,
                isAvailable: false,
                lastError: "目录不存在"
            )
            if !sources.contains(where: { $0.path == seededSource.path }) {
                sources.append(seededSource)
            }
            selectedTab = .sourceManagement
        }
    }

    func addSourceFromInput() {
        let path = sourceInputPath
        sourceInputPath = ""
        _ = addSource(path: path)
    }

    func addGitSourceFromInput() {
        let repoURL = gitRepoInput
        let branch = gitBranchInput.trimmingCharacters(in: .whitespacesAndNewlines)
        gitRepoInput = ""
        gitBranchInput = branch.isEmpty ? "main" : branch
        addGitSourceInBackground(repoURL: repoURL, branch: branch)
    }

    func pickSourceDirectory() {
        guard let path = fileService.pickDirectory() else { return }
        sourceInputPath = path
        _ = addSource(path: path)
    }

    @discardableResult
    func addSource(path: String) -> Bool {
        let normalizedPath = normalized(path)
        guard !normalizedPath.isEmpty else {
            message = localized(chinese: "路径不能为空", english: "Path cannot be empty")
            return false
        }
        guard fileService.directoryExists(normalizedPath) else {
            message = localized(chinese: "目录不存在：\(normalizedPath)", english: "Directory not found: \(normalizedPath)")
            return false
        }
        guard !sources.contains(where: { normalized($0.path) == normalizedPath }) else {
            message = localized(chinese: "来源目录已存在", english: "Source directory already exists")
            return false
        }

        let displayName = URL(fileURLWithPath: normalizedPath).lastPathComponent
        let source = Source(
            path: normalizedPath,
            displayName: displayName.isEmpty ? normalizedPath : displayName
        )
        sources.append(source)
        persistAppConfig()
        refreshSkills()
        message = localized(chinese: "已添加来源：\(source.displayName)", english: "Added source: \(source.displayName)")
        return true
    }

    func removeSource(_ source: Source) {
        if source.isBuiltIn {
            message = localized(chinese: "内置来源不可移除", english: "Built-in source cannot be removed")
            return
        }
        sources.removeAll { $0.id == source.id }
        persistAppConfig()
        refreshSkills()
        message = localized(chinese: "已移除来源：\(source.displayName)", english: "Removed source: \(source.displayName)")
    }

    @discardableResult
    func addGitSource(repoURL: String, branch: String?) -> Bool {
        let normalizedRepoURL = repoURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedRepoURL.isEmpty else {
            message = localized(
                key: "git.repo.empty",
                chinese: "仓库地址不能为空",
                english: "Repository URL cannot be empty"
            )
            return false
        }
        guard !sources.contains(where: { $0.type == .git && $0.repoURL == normalizedRepoURL }) else {
            message = localized(
                key: "git.source.exists",
                chinese: "Git 来源已存在",
                english: "Git source already exists"
            )
            return false
        }

        let targetPath = buildGitSourcePath(repoURL: normalizedRepoURL)
        let fallbackName = URL(string: normalizedRepoURL)?
            .deletingPathExtension()
            .lastPathComponent
            .replacingOccurrences(of: ".git", with: "")
        let displayName = fallbackName?.isEmpty == false ? fallbackName! : "Git 来源"
        let normalizedBranch = branch?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cloneResult = gitService.clone(
            repoURL: normalizedRepoURL,
            branch: normalizedBranch?.isEmpty == true ? nil : normalizedBranch,
            to: targetPath
        )

        switch cloneResult {
        case .success:
            let source = Source(
                path: targetPath,
                displayName: displayName,
                type: .git,
                repoURL: normalizedRepoURL,
                branch: normalizedBranch?.isEmpty == true ? nil : normalizedBranch,
                isAvailable: true,
                lastError: nil
            )
            sources.append(source)
            persistAppConfig()
            refreshSkills()
            message = localized(chinese: "已添加 Git 来源：\(source.displayName)", english: "Added Git source: \(source.displayName)")
            return true
        case .failure(let error):
            let source = Source(
                path: targetPath,
                displayName: displayName,
                type: .git,
                repoURL: normalizedRepoURL,
                branch: normalizedBranch?.isEmpty == true ? nil : normalizedBranch,
                isAvailable: false,
                lastError: error.localizedDescription
            )
            sources.append(source)
            persistAppConfig()
            refreshSkills()
            message = localized(chinese: "哎呀，Git 仓库拉取失败：\(source.displayName)", english: "Oops, failed to clone Git repository: \(source.displayName)")
            return false
        }
    }

    func updateGitSourceInBackground(_ source: Source) {
        guard source.type == .git else { return }
        Task {
            await updateGitSourceAsync(source)
        }
    }

    @discardableResult
    func updateGitSource(_ source: Source) -> Bool {
        guard source.type == .git else { return false }
        let branch = source.branch?.trimmingCharacters(in: .whitespacesAndNewlines)
        let result: Result<Void, Error>
        if fileService.directoryExists(source.path) {
            result = gitService.pull(localPath: source.path, branch: branch?.isEmpty == true ? nil : branch)
        } else if let repoURL = source.repoURL {
            result = gitService.clone(
                repoURL: repoURL,
                branch: branch?.isEmpty == true ? nil : branch,
                to: source.path
            )
        } else {
            result = .failure(
                GitServiceError(
                    message: localized(
                        key: "git.repo.missing",
                        chinese: "缺少仓库地址",
                        english: "Missing repository URL"
                    )
                )
            )
        }

        switch result {
        case .success:
            replaceSource(source.withAvailability(isAvailable: true, lastError: nil))
            persistAppConfig()
            refreshSkillsForCurrentMode()
            message = localized(chinese: "已更新 Git 来源：\(source.displayName)", english: "Updated Git source: \(source.displayName)")
            return true
        case .failure(let error):
            replaceSource(source.withAvailability(isAvailable: false, lastError: error.localizedDescription))
            persistAppConfig()
            message = localized(chinese: "哎呀，更新失败：\(source.displayName)", english: "Oops, update failed: \(source.displayName)")
            return false
        }
    }

    func retrySource(_ source: Source) {
        if source.type == .git {
            updateGitSourceInBackground(source)
            return
        }
        if fileService.directoryExists(source.path) {
            replaceSource(source.withAvailability(isAvailable: true, lastError: nil))
            persistAppConfig()
            message = localized(chinese: "来源恢复可用：\(source.displayName)", english: "Source restored: \(source.displayName)")
        } else {
            replaceSource(
                source.withAvailability(
                    isAvailable: false,
                    lastError: localized(
                        key: "source.error.directoryNotFound",
                        chinese: "目录不存在",
                        english: "Directory not found"
                    )
                )
            )
            persistAppConfig()
            message = localized(chinese: "哎呀，目录还是不可用：\(source.displayName)", english: "Oops, source is still unavailable: \(source.displayName)")
        }
    }

    func updateAllGitSourcesInBackground() {
        let gitSources = sources.filter { $0.type == .git }
        guard !gitSources.isEmpty else {
            message = localized(
                key: "git.batch.none",
                chinese: "暂无 Git 来源可更新",
                english: "No Git sources available to update"
            )
            return
        }
        Task {
            var successCount = 0
            for source in gitSources {
                if await updateGitSourceAsync(source, refreshAfterSuccess: false) {
                    successCount += 1
                }
            }
            persistAppConfig()
            refreshSkillsForCurrentMode()
            if successCount == gitSources.count {
                message = localized(chinese: "Git 来源全部更新完成（\(successCount)/\(gitSources.count)）", english: "All Git sources updated (\(successCount)/\(gitSources.count))")
            } else {
                message = localized(chinese: "Git 来源更新完成（成功 \(successCount)/\(gitSources.count)）", english: "Git source update finished (success \(successCount)/\(gitSources.count))")
            }
            gitProgressMessage = nil
        }
    }

    func selectTab(_ tab: SidebarTab) {
        guard selectedTab != tab else { return }
        selectedTab = tab
        if tab != .appSkills {
            latestSyncDiagnostics = nil
        }
        persistAppConfig()
    }

    func selectApp(_ app: AppTarget) {
        guard selectedApp != app || selectedTab != .appSkills else { return }
        selectedApp = app
        selectedTab = .appSkills
        selectedSourceFilterID = nil
        latestSyncDiagnostics = nil
        ensureDefaultSource()
        refreshSkillsForCurrentMode()
        persistAppConfig()
    }

    func setThemeMode(_ mode: ThemeMode) {
        guard themeMode != mode else { return }
        themeMode = mode
        persistAppConfig()
        message = localized(chinese: "主题已切换为\(themeModeLabel(mode))", english: "Theme changed to \(themeModeLabel(mode))")
    }

    func selectSkillViewMode(_ mode: SkillViewMode) {
        guard skillViewMode != mode else { return }
        skillViewMode = mode
        refreshSkillsForCurrentMode()
        persistAppConfig()
    }

    func setLanguage(_ language: Language) {
        guard self.language != language else { return }
        self.language = language
        persistAppConfig()
        if language == .chinese {
            message = localized(
                key: "toast.language.chinese",
                chinese: "语言已切换至 简体中文",
                english: "Language changed to Chinese (Simplified)"
            )
        } else {
            message = localized(
                key: "toast.language.english",
                chinese: "语言已切换至 English",
                english: "Language changed to English"
            )
        }
    }

    func installSkillFromRepository(_ skill: Skill) {
        let fileManager = FileManager.default
        let targetRootURL = URL(fileURLWithPath: selectedAppSkillsPath, isDirectory: true).standardizedFileURL
        let destinationURL = targetRootURL.appendingPathComponent(skill.folderName, isDirectory: true).standardizedFileURL
        let sourceURL = URL(fileURLWithPath: skill.fullPath, isDirectory: true).standardizedFileURL
        do {
            try fileManager.createDirectory(at: targetRootURL, withIntermediateDirectories: true)
            if fileManager.fileExists(atPath: destinationURL.path) {
                guard let existingType = try fileManager.attributesOfItem(atPath: destinationURL.path)[.type] as? FileAttributeType else {
                    message = localized(chinese: "哎呀，安装失败：\(skill.name)", english: "Oops, install failed: \(skill.name)")
                    return
                }
                if existingType == .typeSymbolicLink {
                    let existingDestination = try resolvedSymlinkDestination(at: destinationURL.path)
                    if existingDestination == sourceURL.path {
                        message = localized(chinese: "已安装：\(skill.name)", english: "Already installed: \(skill.name)")
                        return
                    }
                } else {
                    if existingType != .typeDirectory && existingType != .typeRegular {
                        message = localized(chinese: "哎呀，安装失败：目标路径不可覆盖", english: "Oops, install failed: target path cannot be replaced")
                        return
                    }
                }
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.createSymbolicLink(atPath: destinationURL.path, withDestinationPath: sourceURL.path)
            refreshInstalledSkills()
            if skillViewMode == .sourceRepository {
                refreshRepositorySkills()
            }
            message = localized(chinese: "已安装 Skill：\(skill.name)", english: "Installed skill: \(skill.name)")
        } catch {
            message = localized(chinese: "哎呀，安装失败：\(skill.name)", english: "Oops, install failed: \(skill.name)")
        }
    }

    var prefersChinese: Bool {
        language == .chinese
    }

    func localized(chinese: String, english: String) -> String {
        prefersChinese ? chinese : english
    }

    func localized(key: String, chinese: String, english: String) -> String {
        let localeIdentifier = prefersChinese ? "zh-Hans" : "en"
        if let localizedValue = localizedValueFromBundle(key: key, localeIdentifier: localeIdentifier) {
            return localizedValue
        }
        return prefersChinese ? chinese : english
    }

    private func localizedValueFromBundle(key: String, localeIdentifier: String) -> String? {
        guard
            let lprojPath = Bundle.main.path(forResource: localeIdentifier, ofType: "lproj"),
            let localizedBundle = Bundle(path: lprojPath)
        else {
            return nil
        }
        let value = localizedBundle.localizedString(forKey: key, value: nil, table: nil)
        return value == key ? nil : value
    }

    func clearSyncDiagnostics() {
        latestSyncDiagnostics = nil
    }

    func copyLatestSyncDiagnostics() {
        guard let diagnostics = latestSyncDiagnostics, diagnostics.hasIssues else {
            message = localized(chinese: "暂无可复制的同步详情", english: "No sync diagnostics available to copy")
            return
        }
        let report = buildSyncDiagnosticsReport(diagnostics)
        if fileService.copyTextToClipboard(report) {
            message = localized(chinese: "同步异常详情已复制", english: "Sync diagnostics copied")
        } else {
            message = localized(chinese: "哎呀，复制失败，请稍后重试", english: "Oops, copy failed, please try again")
        }
    }

    func exportLatestSyncDiagnostics() {
        guard let diagnostics = latestSyncDiagnostics, diagnostics.hasIssues else {
            message = localized(chinese: "暂无可导出的同步详情", english: "No sync diagnostics available to export")
            return
        }
        let report = buildSyncDiagnosticsReport(diagnostics)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let filename = "skilldock-sync-diagnostics-\(formatter.string(from: Date())).txt"
        switch fileService.saveTextWithPanel(defaultFileName: filename, content: report) {
        case .success(let path):
            message = localized(chinese: "已导出同步日志：\(path)", english: "Exported sync log: \(path)")
        case .cancelled:
            message = localized(chinese: "已取消导出", english: "Export cancelled")
        case .permissionDenied:
            message = localized(chinese: "哎呀，没有写入权限，请选择其他目录", english: "Oops, no write permission, please choose another folder")
        case .writeFailed:
            message = localized(chinese: "哎呀，写入失败，请稍后重试", english: "Oops, failed to write file, please try again")
        case .unsupported:
            message = localized(chinese: "当前系统暂不支持导出", english: "Export is not supported on this system")
        }
    }

    var selectedAppName: String {
        selectedApp.displayName
    }

    var selectedAppSkillsPath: String {
        normalized(appSkillsPathResolver(selectedApp))
    }

    var filteredSkills: [Skill] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let selectedSourceID = selectedSourceFilterID
        let filtered = displayedSkills.filter { skill in
            let matchesSource = selectedSourceID == nil || skill.sourceID == selectedSourceID
            let matchesKeyword = keyword.isEmpty
                || skill.name.localizedCaseInsensitiveContains(keyword)
                || skill.description.localizedCaseInsensitiveContains(keyword)
            return matchesSource && matchesKeyword
        }
        if skillViewMode == .sourceRepository {
            let installedNames = installedSkillFolderNames
            return filtered.sorted { lhs, rhs in
                let lhsInstalled = installedNames.contains(lhs.folderName)
                let rhsInstalled = installedNames.contains(rhs.folderName)
                if lhsInstalled != rhsInstalled {
                    return !lhsInstalled && rhsInstalled
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        }
        return filtered
    }

    var displayedSkills: [Skill] {
        switch skillViewMode {
        case .installedOnly:
            return skills
        case .sourceRepository:
            return repositorySkills
        }
    }

    var sourceSkillCounts: [UUID: Int] {
        Dictionary(grouping: displayedSkills, by: \.sourceID).mapValues(\.count)
    }

    var installedSkillFolderNames: Set<String> {
        Set(skills.map(\.folderName))
    }

    func isSkillInstalled(_ skill: Skill) -> Bool {
        installedSkillFolderNames.contains(skill.folderName)
    }

    func isSkillEnabled(_ skill: Skill) -> Bool {
        let states = activeSkillStates()
        if let exact = states[skill.id] {
            return exact
        }
        let suffix = "#\(skill.folderName)"
        if let legacy = states.first(where: { $0.key.hasSuffix(suffix) })?.value {
            return legacy
        }
        return true
    }

    func setSkillEnabled(_ enabled: Bool, for skill: Skill) {
        globalSkillStates[skill.id] = enabled
        applySkillStates()
        persistAppConfig()
    }

    func refreshSkills() {
        var scanErrors: [String] = []
        var latestSources: [Source] = []

        for source in sources {
            guard fileService.directoryExists(source.path) else {
                latestSources.append(source.withAvailability(isAvailable: false, lastError: localized(chinese: "目录不存在", english: "Directory not found")))
                scanErrors.append(localized(chinese: "\(source.displayName) 扫描失败", english: "Failed to scan \(source.displayName)"))
                continue
            }
            latestSources.append(source.withAvailability(isAvailable: true, lastError: nil))
        }

        sources = latestSources
        refreshSkillsForCurrentMode()
        persistAppConfig()
        if !scanErrors.isEmpty {
            message = scanErrors.joined(separator: "；")
        }
    }

    func syncSkills() {
        guard !isSyncing else { return }
        isSyncing = true
        var incoming: [Skill] = []
        var scanErrors: [String] = []
        latestSyncDiagnostics = nil

        for source in sources {
            guard fileService.directoryExists(source.path) else {
                scanErrors.append(localized(chinese: "\(source.displayName) 扫描失败", english: "Failed to scan \(source.displayName)"))
                continue
            }
            do {
                let scanned = try skillScanner.scanDirectory(source.path, sourceID: source.id)
                incoming.append(contentsOf: scanned)
            } catch {
                scanErrors.append(localized(chinese: "\(source.displayName) 扫描失败", english: "Failed to scan \(source.displayName)"))
            }
        }

        incoming.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        let currentInstalledSkills = (try? loadInstalledSkills()) ?? []
        let currentFolderNames = Set(currentInstalledSkills.map(\.folderName))
        let incomingFolderNames = Set(incoming.map(\.folderName))
        let addedCount = incomingFolderNames.subtracting(currentFolderNames).count
        let removedCount = currentFolderNames.subtracting(incomingFolderNames).count
        let conflicts = makeConflicts(current: skills, incoming: incoming)

        if conflicts.isEmpty {
            pendingSyncPreview = nil
            message = localized(chinese: "同步完成：新增 \(addedCount) 个，移除 \(removedCount) 个", english: "Sync completed: added \(addedCount), removed \(removedCount)")
            let diagnostics = syncSkillsToSelectedAppDirectory(from: incoming)
            if diagnostics.hasIssues {
                latestSyncDiagnostics = diagnostics
            }
            if let syncSummary = diagnostics.summaryMessage(prefersChinese: prefersChinese) {
                appendMessage(syncSummary)
            }
            if !scanErrors.isEmpty {
                appendMessage(scanErrors.joined(separator: "；"))
            }
            refreshInstalledSkills()
            isSyncing = false
            return
        }

        pendingSyncPreview = SyncPreview(
            incomingSkills: incoming,
            addedCount: addedCount,
            removedCount: removedCount,
            conflicts: conflicts
        )
        latestSyncDiagnostics = nil
        message = localized(chinese: "检测到 \(conflicts.count) 个同名冲突，请选择处理方式", english: "Detected \(conflicts.count) name conflicts, choose how to resolve")
        isSyncing = false
    }

    func resolvePendingSync(strategy: ConflictResolutionStrategy) {
        guard let preview = pendingSyncPreview else { return }

        let conflictNames = Set(preview.conflicts.map(\.folderName))
        let nonConflictIncoming = preview.incomingSkills.filter { !conflictNames.contains($0.folderName) }
        let resolved: [Skill]

        switch strategy {
        case .keepExisting, .keepAllExisting:
            let existingConflictSkills = skills.filter { conflictNames.contains($0.folderName) }
            resolved = nonConflictIncoming + existingConflictSkills
        case .replaceWithIncoming, .keepAllIncoming:
            resolved = preview.incomingSkills
        }

        isSyncing = true
        pendingSyncPreview = nil
        message = localized(chinese: "同步完成：新增 \(preview.addedCount) 个，移除 \(preview.removedCount) 个，冲突已处理", english: "Sync completed: added \(preview.addedCount), removed \(preview.removedCount), conflicts resolved")
        let diagnostics = syncSkillsToSelectedAppDirectory(from: resolved)
        if diagnostics.hasIssues {
            latestSyncDiagnostics = diagnostics
        } else {
            latestSyncDiagnostics = nil
        }
        if let syncSummary = diagnostics.summaryMessage(prefersChinese: prefersChinese) {
            appendMessage(syncSummary)
        }
        refreshInstalledSkills()
        isSyncing = false
    }

    func cancelPendingSync() {
        pendingSyncPreview = nil
        message = localized(chinese: "已取消同步冲突处理", english: "Sync conflict resolution cancelled")
    }

    func addGitSourceInBackground(repoURL: String, branch: String?) {
        let normalizedRepoURL = repoURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedRepoURL.isEmpty else {
            message = localized(
                key: "git.repo.empty",
                chinese: "仓库地址不能为空",
                english: "Repository URL cannot be empty"
            )
            return
        }
        guard !sources.contains(where: { $0.type == .git && $0.repoURL == normalizedRepoURL }) else {
            message = localized(
                key: "git.source.exists",
                chinese: "Git 来源已存在",
                english: "Git source already exists"
            )
            return
        }

        let targetPath = buildGitSourcePath(repoURL: normalizedRepoURL)
        let fallbackName = URL(string: normalizedRepoURL)?
            .deletingPathExtension()
            .lastPathComponent
            .replacingOccurrences(of: ".git", with: "")
        let displayName = fallbackName?.isEmpty == false ? fallbackName! : "Git 来源"
        let normalizedBranch = branch?.trimmingCharacters(in: .whitespacesAndNewlines)

        let pendingSource = Source(
            path: targetPath,
            displayName: displayName,
            type: .git,
            repoURL: normalizedRepoURL,
            branch: normalizedBranch?.isEmpty == true ? nil : normalizedBranch,
            isAvailable: false,
            lastError: localized(
                key: "git.clone.inProgress",
                chinese: "克隆中...",
                english: "Cloning..."
            )
        )
        sources.append(pendingSource)
        activeGitSourceIDs.insert(pendingSource.id)
        gitProgressMessage = localized(chinese: "正在克隆 \(displayName) 仓库...", english: "Cloning \(displayName) repository...")
        persistAppConfig()

        Task {
            let maxAttempts = 3
            var attempt = 0
            var success = false
            var lastError: Error?
            while attempt < maxAttempts {
                attempt += 1
                gitProgressMessage = attempt == 1
                    ? localized(chinese: "正在克隆 \(displayName) 仓库...", english: "Cloning \(displayName) repository...")
                    : localized(chinese: "正在克隆 \(displayName) 仓库...（第\(attempt)次）", english: "Cloning \(displayName) repository... (attempt \(attempt))")
                let cloneResult = await gitService.cloneAsync(
                    repoURL: normalizedRepoURL,
                    branch: normalizedBranch?.isEmpty == true ? nil : normalizedBranch,
                    to: targetPath
                )
                switch cloneResult {
                case .success:
                    success = true
                case .failure(let error):
                    lastError = error
                    if attempt < maxAttempts {
                        let delay = retryDelayNanoseconds(attempt: attempt)
                        try? await Task.sleep(nanoseconds: delay)
                    }
                }
                if success {
                    break
                }
            }

            activeGitSourceIDs.remove(pendingSource.id)
            if success {
                replaceSource(pendingSource.withAvailability(isAvailable: true, lastError: nil))
                persistAppConfig()
                refreshSkillsForCurrentMode()
                message = localized(chinese: "已添加 Git 来源：\(displayName)", english: "Added Git source: \(displayName)")
            } else {
                let errorMessage = lastError?.localizedDescription ?? localized(
                    key: "common.error.unknown",
                    chinese: "未知错误",
                    english: "Unknown error"
                )
                replaceSource(
                    pendingSource.withAvailability(
                        isAvailable: false,
                        lastError: localized(chinese: "重试 \(maxAttempts) 次失败：\(errorMessage)", english: "Failed after \(maxAttempts) retries: \(errorMessage)")
                    )
                )
                persistAppConfig()
                message = localized(chinese: "哎呀，Git 仓库拉取失败：\(displayName)", english: "Oops, failed to clone Git repository: \(displayName)")
            }
            if activeGitSourceIDs.isEmpty {
                gitProgressMessage = nil
            }
        }
    }

    func removeInstalledSkill(_ skill: Skill) {
        let targetRoot = URL(fileURLWithPath: selectedAppSkillsPath, isDirectory: true)
        let targetURL = targetRoot.appendingPathComponent(skill.folderName, isDirectory: true)
        if FileManager.default.fileExists(atPath: targetURL.path) {
            do {
                try FileManager.default.removeItem(at: targetURL)
                refreshInstalledSkills()
                message = localized(chinese: "已移除 \(skill.name)", english: "Removed \(skill.name)")
            } catch {
                message = localized(chinese: "哎呀，移除失败：\(skill.name)", english: "Oops, failed to remove: \(skill.name)")
            }
            return
        }
        refreshInstalledSkills()
        message = localized(
            key: "skills.error.notFound",
            chinese: "该 Skill 已不存在",
            english: "This skill no longer exists"
        )
    }

    func clearAllInstalledSkills() {
        let rootURL = URL(fileURLWithPath: selectedAppSkillsPath, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
            let items = try FileManager.default.contentsOfDirectory(
                at: rootURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            for item in items {
                try FileManager.default.removeItem(at: item)
            }
            refreshInstalledSkills()
            message = localized(chinese: "已清空 \(selectedApp.displayName) 的全部 Skill", english: "Cleared all skills for \(selectedApp.displayName)")
        } catch {
            message = localized(chinese: "哎呀，清空失败：\(error.localizedDescription)", english: "Oops, failed to clear skills: \(error.localizedDescription)")
        }
    }

    func refreshInstalledSkills() {
        isLoadingInstalledSkills = true
        ensureDefaultSource()
        do {
            let scanned = try loadInstalledSkills()
            skills = scanned
        } catch {
            skills = []
            appendMessage(
                localized(
                    key: "skills.error.loadInstalledFailed",
                    chinese: "哎呀，读取已安装 Skill 失败",
                    english: "Oops, failed to load installed skills"
                )
            )
        }
        isLoadingInstalledSkills = false
    }

    private func loadInstalledSkills() throws -> [Skill] {
        let installedSourceID = installedSourceIdentifier(for: selectedApp)
        let targetPath = selectedAppSkillsPath
        try FileManager.default.createDirectory(
            atPath: targetPath,
            withIntermediateDirectories: true
        )
        let scanned = try skillScanner.scanDirectory(targetPath, sourceID: installedSourceID)
        return scanned.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    @discardableResult
    private func updateGitSourceAsync(_ source: Source, refreshAfterSuccess: Bool = true) async -> Bool {
        guard source.type == .git else { return false }
        activeGitSourceIDs.insert(source.id)
        gitProgressMessage = localized(chinese: "正在更新 \(source.displayName)...", english: "Updating \(source.displayName)...")
        let branch = source.branch?.trimmingCharacters(in: .whitespacesAndNewlines)
        let result: Result<Void, Error>
        if fileService.directoryExists(source.path) {
            result = await gitService.pullAsync(
                localPath: source.path,
                branch: branch?.isEmpty == true ? nil : branch
            )
        } else if let repoURL = source.repoURL {
            result = await gitService.cloneAsync(
                repoURL: repoURL,
                branch: branch?.isEmpty == true ? nil : branch,
                to: source.path
            )
        } else {
            result = .failure(
                GitServiceError(
                    message: localized(
                        key: "git.repo.missing",
                        chinese: "缺少仓库地址",
                        english: "Missing repository URL"
                    )
                )
            )
        }

        activeGitSourceIDs.remove(source.id)
        switch result {
        case .success:
            replaceSource(source.withAvailability(isAvailable: true, lastError: nil))
            persistAppConfig()
            if refreshAfterSuccess {
                refreshInstalledSkills()
                message = localized(chinese: "已更新 Git 来源：\(source.displayName)", english: "Updated Git source: \(source.displayName)")
            }
            if activeGitSourceIDs.isEmpty {
                gitProgressMessage = nil
            }
            return true
        case .failure(let error):
            replaceSource(source.withAvailability(isAvailable: false, lastError: error.localizedDescription))
            persistAppConfig()
            message = localized(chinese: "哎呀，更新失败：\(source.displayName)", english: "Oops, update failed: \(source.displayName)")
            if activeGitSourceIDs.isEmpty {
                gitProgressMessage = nil
            }
            return false
        }
    }

    private func persistAppConfig() {
        var config = configManager.loadAppConfig()
        config.sources = sources
        config.selectedApp = selectedApp
        config.themeMode = themeMode
        config.skillViewMode = skillViewMode
        config.language = language
        config.selectedPage = selectedPage(for: selectedTab)
        config.skillStates = globalSkillStates
        configManager.saveAppConfig(config)
    }

    private func applySkillStates() {
        skills = skills.map { skill in
            var mutable = skill
            mutable.isEnabled = isSkillEnabled(skill)
            return mutable
        }
    }

    private func applyScannedSkills(_ scannedSkills: [Skill]) {
        skills = scannedSkills
        applySkillStates()
    }

    private func makeConflicts(current: [Skill], incoming: [Skill]) -> [SyncConflict] {
        let currentByFolder = Dictionary(grouping: current, by: \.folderName)
        let incomingByFolder = Dictionary(grouping: incoming, by: \.folderName)
        var conflicts: [SyncConflict] = []

        for (folderName, incomingGroup) in incomingByFolder {
            let existingGroup = currentByFolder[folderName] ?? []
            let existingPaths = Set(existingGroup.map { URL(fileURLWithPath: $0.fullPath).standardizedFileURL.path })
            let incomingPaths = Set(incomingGroup.map { URL(fileURLWithPath: $0.fullPath).standardizedFileURL.path })
            let hasDifferentIncoming = !incomingPaths.subtracting(existingPaths).isEmpty
            let hasExisting = !existingGroup.isEmpty
            let hasIncomingDuplicate = incomingPaths.count > 1

            if (hasExisting && hasDifferentIncoming) || hasIncomingDuplicate {
                conflicts.append(
                    SyncConflict(
                        folderName: folderName,
                        existing: existingGroup.sorted { $0.fullPath < $1.fullPath },
                        incoming: incomingGroup.sorted { $0.fullPath < $1.fullPath }
                    )
                )
            }
        }

        return conflicts.sorted { $0.folderName < $1.folderName }
    }

    private func activeSkillStates() -> [String: Bool] {
        globalSkillStates
    }

    private func normalized(_ path: String) -> String {
        (path as NSString).expandingTildeInPath
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/+", with: "/", options: .regularExpression)
    }

    private func installedSourceIdentifier(for app: AppTarget) -> UUID {
        switch app {
        case .claudeCode:
            return UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        case .codex:
            return UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        case .openCode:
            return UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        case .trae:
            return UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        case .traeCN:
            return UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
        case .workBuddy:
            return UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
        case .codeBuddy:
            return UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
        case .aionUI:
            return UUID(uuidString: "88888888-8888-8888-8888-888888888888")!
        case .qoder:
            return UUID(uuidString: "99999999-9999-9999-9999-999999999999")!
        }
    }

    private func replaceSource(_ source: Source) {
        guard let index = sources.firstIndex(where: { $0.id == source.id }) else { return }
        sources[index] = source
    }

    private func buildGitSourcePath(repoURL: String) -> String {
        let root = normalized("~/.skilldock/git-sources")
        let fallback = repoURL
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: ".git", with: "")
        var candidate = "\(root)/\(fallback)"
        var suffix = 1
        while sources.contains(where: { normalized($0.path) == candidate }) {
            suffix += 1
            candidate = "\(root)/\(fallback)-\(suffix)"
        }
        return candidate
    }

    private func retryDelayNanoseconds(attempt: Int) -> UInt64 {
        let baseDelay = 0.6
        let delaySeconds = baseDelay * pow(2.0, Double(max(0, attempt - 1)))
        return UInt64(delaySeconds * 1_000_000_000)
    }

    private func ensureDefaultSource() {
        let defaultPath = normalized(appSkillsPathResolver(selectedApp))
        let displayName = "\(selectedApp.displayName) Skills"
        let hadBuiltIn = sources.contains(where: \.isBuiltIn)
        sources.removeAll { $0.isBuiltIn && normalized($0.path) != defaultPath }

        guard fileService.directoryExists(defaultPath) else {
            if hadBuiltIn {
                persistAppConfig()
            }
            return
        }

        if let index = sources.firstIndex(where: { normalized($0.path) == defaultPath }) {
            let source = sources[index]
            if !source.isBuiltIn || source.displayName != displayName {
                sources[index] = Source(
                    id: source.id,
                    path: source.path,
                    displayName: displayName,
                    addedAt: source.addedAt,
                    type: source.type,
                    repoURL: source.repoURL,
                    branch: source.branch,
                    isAvailable: source.isAvailable,
                    lastError: source.lastError,
                    isBuiltIn: true
                )
                persistAppConfig()
            }
            return
        }

        sources.append(Source(path: defaultPath, displayName: displayName, isBuiltIn: true))
        persistAppConfig()
    }

    private func syncSkillsToSelectedAppDirectory(from skills: [Skill]) -> SyncDiagnostics {
        let fileManager = FileManager.default
        let currentApp = selectedApp
        let targetRootPath = normalized(appSkillsPathResolver(currentApp))
        let targetRootURL = URL(fileURLWithPath: targetRootPath, isDirectory: true)
        var skippedFolderNames: [String] = []
        var warnings: [String] = []

        do {
            try fileManager.createDirectory(at: targetRootURL, withIntermediateDirectories: true)
            let uniqueSkills = deduplicatedSkillsByFolderName(skills)
            let validFolderNames = Set(uniqueSkills.map(\.folderName))
            let sourceRoots = Set(sources.map { normalized($0.path) })
            do {
                try removeStaleManagedLinks(
                    from: targetRootURL,
                    validFolderNames: validFolderNames,
                    sourceRoots: sourceRoots
                )
            } catch {
                warnings.append(localized(chinese: "历史链接清理失败", english: "Failed to clean stale links"))
            }
            for skill in uniqueSkills {
                let destinationURL = targetRootURL
                    .appendingPathComponent(skill.folderName, isDirectory: true)
                    .standardizedFileURL
                do {
                    try fileManager.createDirectory(
                        at: destinationURL.deletingLastPathComponent(),
                        withIntermediateDirectories: true
                    )
                } catch {
                    skippedFolderNames.append(skill.folderName)
                    continue
                }
                let sourceURL = URL(fileURLWithPath: skill.fullPath, isDirectory: true).standardizedFileURL
                if fileManager.fileExists(atPath: destinationURL.path) {
                    guard let existingType = try? fileManager.attributesOfItem(atPath: destinationURL.path)[.type] as? FileAttributeType else {
                        skippedFolderNames.append(skill.folderName)
                        continue
                    }
                    if existingType == .typeSymbolicLink {
                        let existingDestination = (try? resolvedSymlinkDestination(at: destinationURL.path)) ?? ""
                        if existingDestination == sourceURL.path {
                            continue
                        }
                    } else if existingType != .typeDirectory && existingType != .typeRegular {
                        skippedFolderNames.append(skill.folderName)
                        continue
                    }
                    do {
                        try fileManager.removeItem(at: destinationURL)
                    } catch {
                        skippedFolderNames.append(skill.folderName)
                        continue
                    }
                }
                do {
                    try fileManager.createSymbolicLink(
                        atPath: destinationURL.path,
                        withDestinationPath: sourceURL.path
                    )
                } catch {
                    skippedFolderNames.append(skill.folderName)
                }
            }
        } catch {
            return SyncDiagnostics(
                app: currentApp,
                targetPath: targetRootPath,
                skippedFolderNames: [],
                warnings: [],
                fatalError: localized(
                    chinese: "哎呀，\(currentApp.displayName) 同步失败：\(error.localizedDescription)",
                    english: "Oops, failed to sync \(currentApp.displayName): \(error.localizedDescription)"
                )
            )
        }
        return SyncDiagnostics(
            app: currentApp,
            targetPath: targetRootPath,
            skippedFolderNames: skippedFolderNames.sorted(),
            warnings: warnings,
            fatalError: nil
        )
    }

    private func deduplicatedSkillsByFolderName(_ skills: [Skill]) -> [Skill] {
        var seen: Set<String> = []
        var result: [Skill] = []
        for skill in skills.sorted(by: { $0.fullPath < $1.fullPath }) {
            if seen.insert(skill.folderName).inserted {
                result.append(skill)
            }
        }
        return result
    }

    private func removeStaleManagedLinks(from rootURL: URL, validFolderNames: Set<String>, sourceRoots: Set<String>) throws {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isSymbolicLinkKey],
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        for case let linkURL as URL in enumerator {
            let values = try linkURL.resourceValues(forKeys: [.isSymbolicLinkKey])
            guard values.isSymbolicLink == true else { continue }
            let relative = String(linkURL.path.dropFirst(rootURL.path.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if validFolderNames.contains(relative) {
                continue
            }
            let destination = try resolvedSymlinkDestination(at: linkURL.path)
            if sourceRoots.contains(where: { destination == $0 || destination.hasPrefix($0 + "/") }) {
                try fileManager.removeItem(at: linkURL)
            }
        }
    }

    private func resolvedSymlinkDestination(at path: String) throws -> String {
        let fileManager = FileManager.default
        let rawDestination = try fileManager.destinationOfSymbolicLink(atPath: path)
        if rawDestination.hasPrefix("/") {
            return URL(fileURLWithPath: rawDestination).standardizedFileURL.path
        }
        let baseURL = URL(fileURLWithPath: path).deletingLastPathComponent()
        return baseURL.appendingPathComponent(rawDestination).standardizedFileURL.path
    }

    private func appendMessage(_ value: String) {
        guard !value.isEmpty else { return }
        if let existing = message, !existing.isEmpty {
            message = "\(existing)；\(value)"
        } else {
            message = value
        }
    }

    private func scanSkillsFromSources() -> [Skill] {
        var aggregated: [Skill] = []
        for source in sources where source.isAvailable && !source.isBuiltIn {
            do {
                let scanned = try skillScanner.scanDirectory(source.path, sourceID: source.id)
                aggregated.append(contentsOf: scanned)
            } catch {
                continue
            }
        }
        return aggregated.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func refreshRepositorySkills() {
        isLoadingRepositorySkills = true
        repositorySkills = scanSkillsFromSources()
        isLoadingRepositorySkills = false
    }

    private func refreshSkillsForCurrentMode() {
        switch skillViewMode {
        case .installedOnly:
            refreshInstalledSkills()
        case .sourceRepository:
            refreshRepositorySkills()
        }
    }

    private func themeModeLabel(_ mode: ThemeMode) -> String {
        switch mode {
        case .system:
            return localized(chinese: "跟随系统", english: "System")
        case .light:
            return localized(chinese: "浅色", english: "Light")
        case .dark:
            return localized(chinese: "深色", english: "Dark")
        }
    }

    private func buildSyncDiagnosticsReport(_ diagnostics: SyncDiagnostics) -> String {
        let formatter = ISO8601DateFormatter()
        var lines: [String] = []
        lines.append(localized(chinese: "SkillDock 同步异常详情", english: "SkillDock Sync Diagnostics"))
        lines.append(localized(chinese: "时间：\(formatter.string(from: Date()))", english: "Time: \(formatter.string(from: Date()))"))
        lines.append(localized(chinese: "应用：\(diagnostics.app.displayName)", english: "App: \(diagnostics.app.displayName)"))
        let reportPath = diagnostics.targetPath.isEmpty ? selectedAppSkillsPath : diagnostics.targetPath
        lines.append(localized(chinese: "目标目录：\(reportPath)", english: "Target path: \(reportPath)"))
        if let fatalError = diagnostics.fatalError, !fatalError.isEmpty {
            lines.append(localized(chinese: "错误：\(fatalError)", english: "Error: \(fatalError)"))
        }
        if !diagnostics.skippedFolderNames.isEmpty {
            lines.append(localized(chinese: "跳过项：\(diagnostics.skippedFolderNames.joined(separator: "、"))", english: "Skipped: \(diagnostics.skippedFolderNames.joined(separator: ", "))"))
        }
        if !diagnostics.warnings.isEmpty {
            lines.append(localized(chinese: "提示：\(diagnostics.warnings.joined(separator: "；"))", english: "Warnings: \(diagnostics.warnings.joined(separator: "; "))"))
        }
        return lines.joined(separator: "\n")
    }

    private func selectedPage(for tab: SidebarTab) -> NavigationPage {
        switch tab {
        case .appSkills:
            return .skills
        case .sourceManagement:
            return .sourceManagement
        case .settings:
            return .settings
        }
    }

    private func sidebarTab(for page: NavigationPage) -> SidebarTab {
        switch page {
        case .skills:
            return .appSkills
        case .sourceManagement:
            return .sourceManagement
        case .settings:
            return .settings
        }
    }
}
