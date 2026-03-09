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
    let skippedFolderNames: [String]
    let warnings: [String]
    let fatalError: String?

    var hasIssues: Bool {
        fatalError != nil || !skippedFolderNames.isEmpty || !warnings.isEmpty
    }

    var summaryMessage: String? {
        if let fatalError {
            return fatalError
        }
        guard hasIssues else {
            return nil
        }
        var summary: [String] = []
        if !skippedFolderNames.isEmpty {
            summary.append("跳过 \(skippedFolderNames.count) 个冲突项")
        }
        if !warnings.isEmpty {
            summary.append(contentsOf: warnings)
        }
        return summary.joined(separator: "，")
    }
}

@MainActor
final class MainViewModel: ObservableObject {
    @Published var selectedTab: SidebarTab = .appSkills
    @Published private(set) var selectedApp: AppTarget = .claudeCode
    @Published private(set) var themeMode: ThemeMode = .system
    @Published private(set) var sources: [Source] = []
    @Published private(set) var skills: [Skill] = []
    @Published var sourceInputPath: String = ""
    @Published var gitRepoInput: String = ""
    @Published var gitBranchInput: String = "main"
    @Published var searchText: String = ""
    @Published var selectedSourceFilterID: UUID?
    @Published private(set) var pendingSyncPreview: SyncPreview?
    @Published private(set) var latestSyncDiagnostics: SyncDiagnostics?
    @Published private(set) var isLoadingInstalledSkills: Bool = false
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
        if arguments.contains("-uitest_seed_toast_warning") {
            Task { @MainActor in
                self.message = "暂无 Git 来源可更新"
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
            message = "路径不能为空"
            return false
        }
        guard fileService.directoryExists(normalizedPath) else {
            message = "目录不存在：\(normalizedPath)"
            return false
        }
        guard !sources.contains(where: { normalized($0.path) == normalizedPath }) else {
            message = "来源目录已存在"
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
        message = "已添加来源：\(source.displayName)"
        return true
    }

    func removeSource(_ source: Source) {
        if source.isBuiltIn {
            message = "内置来源不可移除"
            return
        }
        sources.removeAll { $0.id == source.id }
        persistAppConfig()
        refreshSkills()
        message = "已移除来源：\(source.displayName)"
    }

    @discardableResult
    func addGitSource(repoURL: String, branch: String?) -> Bool {
        let normalizedRepoURL = repoURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedRepoURL.isEmpty else {
            message = "仓库地址不能为空"
            return false
        }
        guard !sources.contains(where: { $0.type == .git && $0.repoURL == normalizedRepoURL }) else {
            message = "Git 来源已存在"
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
            message = "已添加 Git 来源：\(source.displayName)"
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
            message = "哎呀，Git 仓库拉取失败：\(source.displayName)"
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
            result = .failure(GitServiceError(message: "缺少仓库地址"))
        }

        switch result {
        case .success:
            replaceSource(source.withAvailability(isAvailable: true, lastError: nil))
            persistAppConfig()
            refreshInstalledSkills()
            message = "已更新 Git 来源：\(source.displayName)"
            return true
        case .failure(let error):
            replaceSource(source.withAvailability(isAvailable: false, lastError: error.localizedDescription))
            persistAppConfig()
            message = "哎呀，更新失败：\(source.displayName)"
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
            message = "来源恢复可用：\(source.displayName)"
        } else {
            replaceSource(source.withAvailability(isAvailable: false, lastError: "目录不存在"))
            persistAppConfig()
            message = "哎呀，目录还是不可用：\(source.displayName)"
        }
    }

    func updateAllGitSourcesInBackground() {
        let gitSources = sources.filter { $0.type == .git }
        guard !gitSources.isEmpty else {
            message = "暂无 Git 来源可更新"
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
            refreshInstalledSkills()
            if successCount == gitSources.count {
                message = "Git 来源全部更新完成（\(successCount)/\(gitSources.count)）"
            } else {
                message = "Git 来源更新完成（成功 \(successCount)/\(gitSources.count)）"
            }
            gitProgressMessage = nil
        }
    }

    func selectTab(_ tab: SidebarTab) {
        guard selectedTab != tab else { return }
        selectedTab = tab
        persistAppConfig()
    }

    func selectApp(_ app: AppTarget) {
        guard selectedApp != app || selectedTab != .appSkills else { return }
        selectedApp = app
        selectedTab = .appSkills
        selectedSourceFilterID = nil
        ensureDefaultSource()
        refreshInstalledSkills()
        persistAppConfig()
        message = "已切换应用：\(app.displayName)"
    }

    func setThemeMode(_ mode: ThemeMode) {
        guard themeMode != mode else { return }
        themeMode = mode
        persistAppConfig()
        message = "主题已切换为\(themeModeLabel(mode))"
    }

    func clearSyncDiagnostics() {
        latestSyncDiagnostics = nil
    }

    func copyLatestSyncDiagnostics() {
        guard let diagnostics = latestSyncDiagnostics, diagnostics.hasIssues else {
            message = "暂无可复制的同步详情"
            return
        }
        let report = buildSyncDiagnosticsReport(diagnostics)
        if fileService.copyTextToClipboard(report) {
            message = "同步异常详情已复制"
        } else {
            message = "哎呀，复制失败，请稍后重试"
        }
    }

    func exportLatestSyncDiagnostics() {
        guard let diagnostics = latestSyncDiagnostics, diagnostics.hasIssues else {
            message = "暂无可导出的同步详情"
            return
        }
        let report = buildSyncDiagnosticsReport(diagnostics)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let filename = "skilldock-sync-diagnostics-\(formatter.string(from: Date())).txt"
        switch fileService.saveTextWithPanel(defaultFileName: filename, content: report) {
        case .success(let path):
            message = "已导出同步日志：\(path)"
        case .cancelled:
            message = "已取消导出"
        case .permissionDenied:
            message = "哎呀，没有写入权限，请选择其他目录"
        case .writeFailed:
            message = "哎呀，写入失败，请稍后重试"
        case .unsupported:
            message = "当前系统暂不支持导出"
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
        return skills.filter { skill in
            keyword.isEmpty
            || skill.name.localizedCaseInsensitiveContains(keyword)
            || skill.description.localizedCaseInsensitiveContains(keyword)
        }
    }

    var sourceSkillCounts: [UUID: Int] {
        Dictionary(grouping: skills, by: \.sourceID).mapValues(\.count)
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
                latestSources.append(source.withAvailability(isAvailable: false, lastError: "目录不存在"))
                scanErrors.append("\(source.displayName) 扫描失败")
                continue
            }
            latestSources.append(source.withAvailability(isAvailable: true, lastError: nil))
        }

        sources = latestSources
        refreshInstalledSkills()
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
                scanErrors.append("\(source.displayName) 扫描失败")
                continue
            }
            do {
                let scanned = try skillScanner.scanDirectory(source.path, sourceID: source.id)
                incoming.append(contentsOf: scanned)
            } catch {
                scanErrors.append("\(source.displayName) 扫描失败")
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
            message = "同步完成：新增 \(addedCount) 个，移除 \(removedCount) 个"
            let diagnostics = syncSkillsToSelectedAppDirectory(from: incoming)
            if diagnostics.hasIssues {
                latestSyncDiagnostics = diagnostics
            }
            if let syncSummary = diagnostics.summaryMessage {
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
        message = "检测到 \(conflicts.count) 个同名冲突，请选择处理方式"
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
        message = "同步完成：新增 \(preview.addedCount) 个，移除 \(preview.removedCount) 个，冲突已处理"
        let diagnostics = syncSkillsToSelectedAppDirectory(from: resolved)
        if diagnostics.hasIssues {
            latestSyncDiagnostics = diagnostics
        } else {
            latestSyncDiagnostics = nil
        }
        if let syncSummary = diagnostics.summaryMessage {
            appendMessage(syncSummary)
        }
        refreshInstalledSkills()
        isSyncing = false
    }

    func cancelPendingSync() {
        pendingSyncPreview = nil
        message = "已取消同步冲突处理"
    }

    func addGitSourceInBackground(repoURL: String, branch: String?) {
        let normalizedRepoURL = repoURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedRepoURL.isEmpty else {
            message = "仓库地址不能为空"
            return
        }
        guard !sources.contains(where: { $0.type == .git && $0.repoURL == normalizedRepoURL }) else {
            message = "Git 来源已存在"
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
            lastError: "克隆中..."
        )
        sources.append(pendingSource)
        activeGitSourceIDs.insert(pendingSource.id)
        gitProgressMessage = "正在克隆 \(displayName) 仓库..."
        persistAppConfig()

        Task {
            let maxAttempts = 3
            var attempt = 0
            var success = false
            var lastError: Error?
            while attempt < maxAttempts {
                attempt += 1
                gitProgressMessage = attempt == 1
                    ? "正在克隆 \(displayName) 仓库..."
                    : "正在克隆 \(displayName) 仓库...（第\(attempt)次）"
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
                refreshInstalledSkills()
                message = "已添加 Git 来源：\(displayName)"
            } else {
                let errorMessage = lastError?.localizedDescription ?? "未知错误"
                replaceSource(
                    pendingSource.withAvailability(
                        isAvailable: false,
                        lastError: "重试 \(maxAttempts) 次失败：\(errorMessage)"
                    )
                )
                persistAppConfig()
                message = "哎呀，Git 仓库拉取失败：\(displayName)"
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
                message = "已移除 \(skill.name)"
            } catch {
                message = "哎呀，移除失败：\(skill.name)"
            }
            return
        }
        refreshInstalledSkills()
        message = "该 Skill 已不存在"
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
            message = "已清空 \(selectedApp.displayName) 的全部 Skill"
        } catch {
            message = "哎呀，清空失败：\(error.localizedDescription)"
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
            appendMessage("哎呀，读取已安装 Skill 失败")
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
        gitProgressMessage = "正在更新 \(source.displayName)..."
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
            result = .failure(GitServiceError(message: "缺少仓库地址"))
        }

        activeGitSourceIDs.remove(source.id)
        switch result {
        case .success:
            replaceSource(source.withAvailability(isAvailable: true, lastError: nil))
            persistAppConfig()
            if refreshAfterSuccess {
                refreshInstalledSkills()
                message = "已更新 Git 来源：\(source.displayName)"
            }
            if activeGitSourceIDs.isEmpty {
                gitProgressMessage = nil
            }
            return true
        case .failure(let error):
            replaceSource(source.withAvailability(isAvailable: false, lastError: error.localizedDescription))
            persistAppConfig()
            message = "哎呀，更新失败：\(source.displayName)"
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
            let existingIDs = Set(existingGroup.map(\.id))
            let incomingIDs = Set(incomingGroup.map(\.id))
            let hasDifferentIncoming = !incomingIDs.subtracting(existingIDs).isEmpty
            let hasExisting = !existingGroup.isEmpty
            let hasIncomingDuplicate = incomingGroup.count > 1

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
        let targetRootPath = normalized(appSkillsPathResolver(selectedApp))
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
                warnings.append("历史链接清理失败")
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
                    if existingType != .typeSymbolicLink {
                        skippedFolderNames.append(skill.folderName)
                        continue
                    }
                    let existingDestination = (try? resolvedSymlinkDestination(at: destinationURL.path)) ?? ""
                    if existingDestination == sourceURL.path {
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
                skippedFolderNames: [],
                warnings: [],
                fatalError: "哎呀，\(selectedApp.displayName) 同步失败：\(error.localizedDescription)"
            )
        }
        return SyncDiagnostics(
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
        for source in sources where source.isAvailable {
            do {
                let scanned = try skillScanner.scanDirectory(source.path, sourceID: source.id)
                aggregated.append(contentsOf: scanned)
            } catch {
                continue
            }
        }
        return aggregated.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func themeModeLabel(_ mode: ThemeMode) -> String {
        switch mode {
        case .system:
            return "跟随系统"
        case .light:
            return "浅色"
        case .dark:
            return "深色"
        }
    }

    private func buildSyncDiagnosticsReport(_ diagnostics: SyncDiagnostics) -> String {
        let formatter = ISO8601DateFormatter()
        var lines: [String] = []
        lines.append("SkillDock 同步异常详情")
        lines.append("时间：\(formatter.string(from: Date()))")
        lines.append("应用：\(selectedApp.displayName)")
        lines.append("目标目录：\(selectedAppSkillsPath)")
        if let fatalError = diagnostics.fatalError, !fatalError.isEmpty {
            lines.append("错误：\(fatalError)")
        }
        if !diagnostics.skippedFolderNames.isEmpty {
            lines.append("跳过项：\(diagnostics.skippedFolderNames.joined(separator: "、"))")
        }
        if !diagnostics.warnings.isEmpty {
            lines.append("提示：\(diagnostics.warnings.joined(separator: "；"))")
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
