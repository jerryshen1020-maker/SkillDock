import SwiftUI

struct SourceManagementView: View {
    @EnvironmentObject private var viewModel: MainViewModel
    @State private var showingAddGitModal = false

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 32) {
                    if !unavailableSources.isEmpty {
                        unavailableBanner
                    }
                    localSection
                    gitSection
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(hex: "#fafbfc"))
        .sheet(isPresented: $showingAddGitModal) {
            AddGitSourceModal(isPresented: $showingAddGitModal)
        }
    }

    private var header: some View {
        HStack {
            Text("来源管理")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(hex: "#212529"))
            Spacer()
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

    private var localSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("本地目录")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#495057"))
                Spacer()
                Button {
                    viewModel.pickSourceDirectory()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("添加目录")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#4c6ef5"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#e7f5ff"))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            VStack(spacing: 8) {
                let localSources = viewModel.sources.filter { $0.type == .local }
                if localSources.isEmpty {
                    emptyRow(text: "暂无本地目录")
                } else {
                    ForEach(localSources) { source in
                        SourceRowView(source: source)
                    }
                }
            }
        }
    }

    private var gitSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Git 仓库")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#495057"))
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        viewModel.updateAllGitSourcesInBackground()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("一键更新")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#495057"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#f1f3f5"))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.activeGitSourceIDs.isEmpty)
                    
                    Button {
                        showingAddGitModal = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("添加仓库")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#4c6ef5"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#e7f5ff"))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            VStack(spacing: 8) {
                if let gitProgressMessage = viewModel.gitProgressMessage {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text(gitProgressMessage)
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
                }
                let gitSources = viewModel.sources.filter { $0.type == .git }
                if gitSources.isEmpty {
                    emptyRow(text: "暂无 Git 仓库")
                } else {
                    ForEach(gitSources) { source in
                        SourceRowView(source: source)
                    }
                }
            }
        }
    }

    private var unavailableSources: [Source] {
        viewModel.sources.filter { !$0.isAvailable }
    }

    private var unavailableBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#fa5252"))
                Text("有来源暂不可用")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "#c92a2a"))
            }
            Text(unavailableSources.map(\.displayName).joined(separator: "、"))
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#e03131"))
        }
        .padding(12)
        .background(Color(hex: "#fff5f5"))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "#ffa8a8"), lineWidth: 1)
        )
        .cornerRadius(10)
        .accessibilityIdentifier("unavailable-sources-banner")
    }

    private func emptyRow(text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(Color(hex: "#adb5bd"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(hex: "#f1f3f5"), lineWidth: 1)
            )
    }
}

struct SourceRowView: View {
    @EnvironmentObject private var viewModel: MainViewModel
    let source: Source
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: source.type == .git ? "shippingbox.fill" : "folder.fill")
                .font(.system(size: 14))
                .foregroundColor(source.isAvailable ? Color(hex: "#adb5bd") : Color(hex: "#fa5252"))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(source.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#212529"))
                if viewModel.activeGitSourceIDs.contains(source.id) {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        Text("处理中...")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#364fc7"))
                    }
                } else {
                    Text(source.path)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#adb5bd"))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if isHovering {
                HStack(spacing: 8) {
                    if source.type == .git {
                        Button {
                            viewModel.updateGitSourceInBackground(source)
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#4c6ef5"))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if !source.isAvailable {
                        Button {
                            viewModel.retrySource(source)
                        } label: {
                            Image(systemName: "exclamationmark.circle")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#fa5252"))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if !source.isBuiltIn {
                        Button {
                            viewModel.removeSource(source)
                        } label: {
                            Text("删除")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "#fa5252"))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    source.isAvailable
                    ? (isHovering ? Color(hex: "#4c6ef5").opacity(0.3) : Color(hex: "#f1f3f5"))
                    : Color(hex: "#ffa8a8"),
                    lineWidth: 1
                )
        )
        .accessibilityIdentifier(source.isAvailable ? "source-row-available" : "source-row-unavailable")
        .onHover { isHovering = $0 }
    }
}

struct AddGitSourceModal: View {
    @EnvironmentObject private var viewModel: MainViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("添加 Git 仓库")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(Color(hex: "#adb5bd"))
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("仓库地址:")
                    .font(.system(size: 13, weight: .medium))
                TextField("https://github.com/...", text: $viewModel.gitRepoInput)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(hex: "#f1f3f5"))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("分支 (可选):")
                    .font(.system(size: 13, weight: .medium))
                TextField("main", text: $viewModel.gitBranchInput)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(hex: "#f1f3f5"))
                    .cornerRadius(8)
            }
            
            HStack(spacing: 12) {
                Button {
                    isPresented = false
                } label: {
                    Text("取消")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#868e96"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#f1f3f5"))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Button {
                    viewModel.addGitSourceFromInput()
                    isPresented = false
                } label: {
                    Text("添加")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#4c6ef5"))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .frame(width: 480)
        .background(Color.white)
    }
}
