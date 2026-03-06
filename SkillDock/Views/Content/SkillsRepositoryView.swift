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
            if let diagnostics = viewModel.latestSyncDiagnostics, diagnostics.hasIssues {
                syncDiagnosticsBanner(diagnostics)
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
            }
            if viewModel.isSyncing {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("正在扫描来源目录并同步...")
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
        .confirmationDialog("移除 Skill", isPresented: Binding(
            get: { pendingRemoveSkill != nil },
            set: { isPresented in
                if !isPresented {
                    pendingRemoveSkill = nil
                }
            }
        ), titleVisibility: .visible) {
            Button("确认移除", role: .destructive) {
                if let skill = pendingRemoveSkill {
                    viewModel.removeInstalledSkill(skill)
                }
                pendingRemoveSkill = nil
            }
            Button("取消", role: .cancel) {
                pendingRemoveSkill = nil
            }
        } message: {
            Text("确定要从 \(viewModel.selectedAppName) 移除「\(pendingRemoveSkill?.name ?? "")」吗？")
        }
        .confirmationDialog("清空全部 Skill", isPresented: $showingClearAllConfirm, titleVisibility: .visible) {
            Button("确认清空", role: .destructive) {
                viewModel.clearAllInstalledSkills()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要清空 \(viewModel.selectedAppName) 的全部 Skill 吗？这会删除当前应用目录下所有技能项，包含历史遗留链接/目录项。")
        }
    }

    private var contentHeader: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Text("\(viewModel.selectedAppName) - Skills")
                Text("共 \(viewModel.filteredSkills.count) 个")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#adb5bd"))
            }
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(Color(hex: "#212529"))
            
            Spacer()

            if !viewModel.filteredSkills.isEmpty {
                Button {
                    showingClearAllConfirm = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("清空全部")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#e67700"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#fff9db"))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }

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
                    Text(viewModel.isSyncing ? "同步中..." : "一键同步")
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
            if viewModel.isLoadingInstalledSkills {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.regular)
                    Text("正在加载已安装的 Skill...")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#868e96"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredSkills.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: 44))
                        .foregroundColor(Color(hex: "#adb5bd"))
                    Text(viewModel.skills.isEmpty ? "暂无已安装的 Skill" : "未找到匹配的 Skill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#868e96"))
                    if viewModel.skills.isEmpty {
                        Text("点击「一键同步」从来源目录安装 Skill 到全局")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#adb5bd"))
                    }
                    if viewModel.skills.isEmpty {
                        Button {
                            viewModel.syncSkills()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                Text("一键同步")
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
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.filteredSkills) { skill in
                            SkillCardView(
                                skill: skill,
                                appName: viewModel.selectedAppName,
                                onRemove: { pendingRemoveSkill = skill },
                                onDetails: { selectedSkill = skill }
                            )
                        }
                    }
                    .padding(24)
                }
            }
        }
    }

    @ViewBuilder
    private func conflictBanner(_ preview: SyncPreview) -> some View {
        HStack(spacing: 8) {
            Text("检测到 \(preview.conflicts.count) 个冲突")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#495057"))
            ForEach(ConflictResolutionStrategy.allCases) { strategy in
                Button(strategy.title) {
                    viewModel.resolvePendingSync(strategy: strategy)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            Button("取消") {
                viewModel.cancelPendingSync()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
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
                Text("同步完成，但有异常项")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "#495057"))
                Spacer()
                Button("知道了") {
                    viewModel.clearSyncDiagnostics()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "#868e96"))
            }
            if let fatalError = diagnostics.fatalError {
                Text(fatalError)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#c92a2a"))
            } else {
                if !diagnostics.skippedFolderNames.isEmpty {
                    Text("跳过项：\(diagnostics.skippedFolderNames.joined(separator: "、"))")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#d9480f"))
                }
                if !diagnostics.warnings.isEmpty {
                    Text("提示：\(diagnostics.warnings.joined(separator: "；"))")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#d9480f"))
                }
            }
            HStack(spacing: 8) {
                Button("重新同步") {
                    viewModel.syncSkills()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(hex: "#4c6ef5"))
                .cornerRadius(8)
                Button("复制详情") {
                    viewModel.copyLatestSyncDiagnostics()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "#495057"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(hex: "#f1f3f5"))
                .cornerRadius(8)
                Button("导出日志") {
                    viewModel.exportLatestSyncDiagnostics()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "#495057"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(hex: "#f1f3f5"))
                .cornerRadius(8)
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
}
