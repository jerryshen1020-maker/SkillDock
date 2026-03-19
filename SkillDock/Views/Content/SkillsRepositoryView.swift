import SwiftUI

struct SkillsRepositoryView: View {
    @EnvironmentObject private var viewModel: MainViewModel
    @Binding var selectedSkill: Skill?
    @State private var pendingRemoveSkill: Skill?
    @State private var showingClearAllConfirm = false

    private let columns = [
        GridItem(.adaptive(minimum: UIStyleConstants.skillCardMinWidth, maximum: 420), spacing: 12, alignment: .top)
    ]

    var body: some View {
        VStack(spacing: 0) {
            contentHeader
            if let preview = viewModel.pendingSyncPreview {
                conflictBanner(preview)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
            }
            if let diagnostics = viewModel.latestSyncDiagnostics, diagnostics.hasIssues, diagnostics.app == viewModel.selectedApp {
                syncDiagnosticsBanner(diagnostics)
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
            }
            if viewModel.isSyncing {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(t("正在扫描来源目录并同步...", "Scanning sources and syncing..."))
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#364fc7"))
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(hex: "#e7f5ff"))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(hex: "#d0ebff"), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .padding(.top, 10)
            }
            skillListSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(hex: "#fafbfc"))
        .confirmationDialog(t("移除 Skill", "Remove Skill"), isPresented: Binding(
            get: { pendingRemoveSkill != nil },
            set: { isPresented in
                if !isPresented {
                    pendingRemoveSkill = nil
                }
            }
        ), titleVisibility: .visible) {
            Button(t("确认移除", "Remove"), role: .destructive) {
                if let skill = pendingRemoveSkill {
                    viewModel.removeInstalledSkill(skill)
                }
                pendingRemoveSkill = nil
            }
            Button(t("取消", "Cancel"), role: .cancel) {
                pendingRemoveSkill = nil
            }
        } message: {
            Text(t("确定要从 \(viewModel.selectedAppName) 移除「\(pendingRemoveSkill?.name ?? "")」吗？", "Remove \"\(pendingRemoveSkill?.name ?? "")\" from \(viewModel.selectedAppName)?"))
        }
        .confirmationDialog(t("清空全部 Skill", "Clear All Skills"), isPresented: $showingClearAllConfirm, titleVisibility: .visible) {
            Button(t("确认清空", "Clear All"), role: .destructive) {
                viewModel.clearAllInstalledSkills()
            }
            Button(t("取消", "Cancel"), role: .cancel) {}
        } message: {
            Text(t("确定要清空 \(viewModel.selectedAppName) 的全部 Skill 吗？这会删除当前应用目录下所有技能项，包含历史遗留链接/目录项。", "Clear all skills under \(viewModel.selectedAppName)? This removes all skill folders and links in current app directory."))
        }
    }

    private var contentHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Text("\(viewModel.selectedAppName) - Skills")
                    Text(t("共 \(viewModel.filteredSkills.count) 个", "\(viewModel.filteredSkills.count) total"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#adb5bd"))
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "#212529"))
                
                Spacer()

                if viewModel.skillViewMode == .installedOnly && !viewModel.filteredSkills.isEmpty {
                    Button {
                        showingClearAllConfirm = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text(t("清空全部", "Clear All"))
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#e67700"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#fff9db"))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .handCursorOnHover()
                }

                if viewModel.skillViewMode == .installedOnly {
                    Button {
                        viewModel.syncSkills()
                    } label: {
                        HStack(spacing: 6) {
                            if viewModel.isSyncing {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text(viewModel.isSyncing ? t("skills.action.syncing", "同步中...", "Syncing...") : t("skills.action.syncNow", "一键同步", "Sync Now"))
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#4c6ef5"))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isSyncing)
                    .handCursorOnHover()
                }
            }
            .frame(height: 40)

            HStack(spacing: 8) {
                modeButton(title: t("skills.mode.installed", "已安装", "Installed"), mode: .installedOnly)
                modeButton(title: t("skills.mode.repository", "本地仓库", "Repository"), mode: .sourceRepository)
                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(hex: "#f1f3f5"))
                .frame(height: 1)
        }
    }

    private var skillListSection: some View {
        Group {
            if viewModel.skillViewMode == .installedOnly ? viewModel.isLoadingInstalledSkills : viewModel.isLoadingRepositorySkills {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.regular)
                    Text(viewModel.skillViewMode == .installedOnly ? t("正在加载已安装的 Skill...", "Loading installed skills...") : t("正在扫描本地仓库...", "Scanning local repository..."))
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#868e96"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredSkills.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: 44))
                        .foregroundColor(Color(hex: "#adb5bd"))
                    Text(emptyTitle)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#868e96"))
                    if let hint = emptyHint {
                        Text(hint)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#adb5bd"))
                    }
                    if viewModel.skillViewMode == .installedOnly && viewModel.displayedSkills.isEmpty {
                        Button {
                            viewModel.syncSkills()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                Text(t("skills.action.syncNow", "一键同步", "Sync Now"))
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: "#4c6ef5"))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isSyncing)
                        .handCursorOnHover()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.filteredSkills) { skill in
                            let isInstalledInApp = viewModel.skillViewMode == .sourceRepository && viewModel.isSkillInstalled(skill)
                            SkillCardView(
                                skill: skill,
                                contextLabel: contextLabel(for: skill),
                                actionTitle: viewModel.skillViewMode == .installedOnly
                                    ? t("skills.action.remove", "移除", "Remove")
                                    : (isInstalledInApp ? t("已安装", "Installed") : t("skills.action.install", "安装", "Install")),
                                actionStyle: viewModel.skillViewMode == .installedOnly
                                    ? .remove
                                    : (isInstalledInApp ? .installed : .install),
                                isActionEnabled: viewModel.skillViewMode == .installedOnly || !isInstalledInApp,
                                detailsTitle: t("skills.action.details", "详情 →", "Details →"),
                                onAction: {
                                    guard viewModel.skillViewMode == .installedOnly || !isInstalledInApp else { return }
                                    if viewModel.skillViewMode == .installedOnly {
                                        pendingRemoveSkill = skill
                                    } else {
                                        viewModel.installSkillFromRepository(skill)
                                    }
                                },
                                onDetails: { selectedSkill = skill }
                            )
                        }
                    }
                    .padding(24)
                }
            }
        }
    }

    private var emptyTitle: String {
        if viewModel.skillViewMode == .installedOnly {
            return viewModel.displayedSkills.isEmpty ? t("skills.empty.installed", "暂无已安装的 Skill", "No installed skills yet") : t("skills.empty.noMatch", "未找到匹配的 Skill", "No matching skills found")
        }
        return viewModel.displayedSkills.isEmpty ? t("skills.empty.repository", "本地仓库暂无 Skill", "No repository skills found") : t("skills.empty.noMatch", "未找到匹配的 Skill", "No matching skills found")
    }

    private var emptyHint: String? {
        if viewModel.skillViewMode == .installedOnly && viewModel.displayedSkills.isEmpty {
            return t("点击「一键同步」从来源目录安装 Skill 到全局", "Use \"Sync Now\" to install skills from your sources")
        }
        if viewModel.skillViewMode == .sourceRepository && viewModel.displayedSkills.isEmpty {
            return t("请先在来源管理中添加可用目录或 Git 仓库", "Add a local directory or Git repository in Sources first")
        }
        return nil
    }

    private func contextLabel(for skill: Skill) -> String {
        if viewModel.skillViewMode == .installedOnly {
            return viewModel.selectedAppName
        }
        return viewModel.sources.first(where: { $0.id == skill.sourceID })?.displayName ?? t("来源目录", "Source")
    }

    private func modeButton(title: String, mode: SkillViewMode) -> some View {
        let isSelected = viewModel.skillViewMode == mode
        return Button {
            viewModel.selectSkillViewMode(mode)
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .white : Color(hex: "#495057"))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? Color(hex: "#4c6ef5") : Color(hex: "#f1f3f5"))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .handCursorOnHover()
    }

    @ViewBuilder
    private func conflictBanner(_ preview: SyncPreview) -> some View {
        HStack(spacing: 8) {
            Text(t("检测到 \(preview.conflicts.count) 个冲突", "\(preview.conflicts.count) conflicts detected"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#495057"))
            ForEach(ConflictResolutionStrategy.allCases) { strategy in
                Button(strategyTitle(strategy)) {
                    viewModel.resolvePendingSync(strategy: strategy)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .handCursorOnHover()
            }
            Button(t("common.cancel", "取消", "Cancel")) {
                viewModel.cancelPendingSync()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .handCursorOnHover()
            Spacer()
        }
        .padding(10)
        .background(Color(hex: "#f1f3f5"))
        .cornerRadius(10)
    }

    @ViewBuilder
    private func syncDiagnosticsBanner(_ diagnostics: SyncDiagnostics) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#e67700"))
                Text(t("skills.diagnostics.title", "同步完成，但有异常项", "Sync finished with warnings"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "#495057"))
                Spacer()
                Button(t("skills.diagnostics.gotIt", "知道了", "Got it")) {
                    viewModel.clearSyncDiagnostics()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "#868e96"))
                .handCursorOnHover()
            }
            if let fatalError = diagnostics.fatalError {
                Text(fatalError)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#c92a2a"))
            } else {
                if !diagnostics.skippedFolderNames.isEmpty {
                    Text(t("跳过项：\(diagnostics.skippedFolderNames.joined(separator: "、"))", "Skipped: \(diagnostics.skippedFolderNames.joined(separator: ", "))"))
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#d9480f"))
                }
                if !diagnostics.warnings.isEmpty {
                    Text(t("提示：\(diagnostics.warnings.joined(separator: "；"))", "Notes: \(diagnostics.warnings.joined(separator: "; "))"))
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#d9480f"))
                }
            }
            HStack(spacing: 8) {
                Button(t("skills.diagnostics.retry", "重新同步", "Retry Sync")) {
                    viewModel.syncSkills()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(hex: "#4c6ef5"))
                .cornerRadius(8)
                .handCursorOnHover()
                Button(t("skills.diagnostics.copy", "复制详情", "Copy Details")) {
                    viewModel.copyLatestSyncDiagnostics()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "#495057"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(hex: "#f1f3f5"))
                .cornerRadius(8)
                .handCursorOnHover()
                Button(t("skills.diagnostics.export", "导出日志", "Export Log")) {
                    viewModel.exportLatestSyncDiagnostics()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "#495057"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(hex: "#f1f3f5"))
                .cornerRadius(8)
                .handCursorOnHover()
                Spacer()
            }
        }
        .padding(12)
        .background(Color(hex: "#fff9db"))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "#ffe066"), lineWidth: 1)
        )
        .cornerRadius(10)
    }

    private func t(_ chinese: String, _ english: String) -> String {
        viewModel.localized(chinese: chinese, english: english)
    }

    private func t(_ key: String, _ chinese: String, _ english: String) -> String {
        viewModel.localized(key: key, chinese: chinese, english: english)
    }

    private func strategyTitle(_ strategy: ConflictResolutionStrategy) -> String {
        switch strategy {
        case .keepExisting:
            return t("skills.conflict.keepExisting", "保留旧的", "Keep Existing")
        case .replaceWithIncoming:
            return t("skills.conflict.useIncoming", "替换为新的", "Use Incoming")
        case .keepAllExisting:
            return t("skills.conflict.keepAllExisting", "全部保留旧的", "Keep All Existing")
        case .keepAllIncoming:
            return t("skills.conflict.useAllIncoming", "全部用新的", "Use All Incoming")
        }
    }
}
