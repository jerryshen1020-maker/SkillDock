import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: MainViewModel
    @State private var selectedSkill: Skill?
    @State private var toasts: [ToastItem] = []
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            topBar
            HStack(spacing: 0) {
                SidebarView()
                content
                    .transition(.opacity)
                    .id("\(viewModel.selectedApp.id)-\(viewModel.selectedTab.id)")
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedApp)
        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedTab)
        .frame(minWidth: 900, minHeight: 600)
        .background(Color(hex: "#fafbfc"))
        .onAppear {
            viewModel.load()
        }
        .onChange(of: viewModel.message) { value in
            guard let value, !value.isEmpty else { return }
            let kind = ToastKind.resolve(from: value)
            let toast = ToastItem(message: value, kind: kind)
            toasts.append(toast)
            if toasts.count > 3 {
                toasts.removeFirst(toasts.count - 3)
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: kind.durationNanoseconds)
                withAnimation(.easeOut(duration: 0.2)) {
                    toasts.removeAll { $0.id == toast.id }
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            VStack(alignment: .trailing, spacing: 8) {
                ForEach(toasts) { toast in
                    Text(toast.message)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Color(hex: toast.kind.colorHex))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.16), radius: 8, x: 0, y: 3)
                        .accessibilityIdentifier("toast-\(toast.kind.identifier)")
                }
            }
            .padding(.trailing, 24)
            .padding(.bottom, 24)
        }
        .sheet(item: $selectedSkill) { skill in
            SkillDetailView(
                skill: skill,
                onRevealInFinder: { FileService().revealInFinder(skill.fullPath) },
                onClose: { selectedSkill = nil }
            )
        }
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#4c6ef5"), Color(hex: "#7950f2")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text("S")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
                Text("SkillDock")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#212529"))
            }
            Spacer()
            ZStack(alignment: .leading) {
                if viewModel.searchText.isEmpty {
                    Text(viewModel.localized(key: "topbar.search.placeholder", chinese: "搜索 skills...", english: "Search skills..."))
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#adb5bd"))
                        .padding(.leading, 36)
                }
                TextField("", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .padding(.leading, 36)
                    .padding(.trailing, 12)
                    .padding(.vertical, 10)
                    .focused($isSearchFocused)
            }
            .frame(maxWidth: 280)
            .background(isSearchFocused ? Color.white : Color(hex: "#f1f3f5"))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSearchFocused ? Color(hex: "#4c6ef5") : .clear, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSearchFocused ? Color(hex: "#4c6ef5").opacity(0.1) : .clear, lineWidth: 3)
            )
            .overlay(alignment: .leading) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#adb5bd"))
                    .padding(.leading, 12)
            }
            .cornerRadius(10)
        }
        .padding(.horizontal, 24)
        .frame(height: 52)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(hex: "#dee2e6"))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.selectedTab {
        case .appSkills:
            SkillsRepositoryView(selectedSkill: $selectedSkill)
        case .sourceManagement:
            SourceManagementView()
        case .settings:
            SettingsView()
        }
    }
}

private struct ToastItem: Identifiable {
    let id = UUID()
    let message: String
    let kind: ToastKind
}

private enum ToastKind {
    case success
    case warning
    case error

    var colorHex: String {
        switch self {
        case .success:
            return "#40c057"
        case .warning:
            return "#fab005"
        case .error:
            return "#fa5252"
        }
    }

    var durationNanoseconds: UInt64 {
        switch self {
        case .success, .warning:
            return 3_000_000_000
        case .error:
            return 5_000_000_000
        }
    }

    var identifier: String {
        switch self {
        case .success:
            return "success"
        case .warning:
            return "warning"
        case .error:
            return "error"
        }
    }

    static func resolve(from message: String) -> ToastKind {
        if message.contains("哎呀")
            || message.contains("失败")
            || message.contains("错误")
            || message.localizedCaseInsensitiveContains("oops")
            || message.localizedCaseInsensitiveContains("failed")
            || message.localizedCaseInsensitiveContains("error") {
            return .error
        }
        if message.contains("取消")
            || message.contains("冲突")
            || message.contains("暂无")
            || message.localizedCaseInsensitiveContains("cancel")
            || message.localizedCaseInsensitiveContains("conflict")
            || message.localizedCaseInsensitiveContains("no ") {
            return .warning
        }
        return .success
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MainViewModel())
    }
}
