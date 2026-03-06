import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: MainViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                syncCard
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(hex: "#fafbfc"))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("设置")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(hex: "#212529"))
            Text("在这里查看当前应用目录并执行基础维护操作。")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#868e96"))
        }
    }

    private var syncCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("同步与目录")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "#212529"))
            row(label: "当前应用", value: viewModel.selectedAppName)
            row(label: "目标目录", value: viewModel.selectedAppSkillsPath)
            HStack(spacing: 8) {
                Button("在 Finder 中显示目录") {
                    FileService().revealInFinder(viewModel.selectedAppSkillsPath)
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "#364fc7"))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color(hex: "#edf2ff"))
                .cornerRadius(8)
                Button("重新扫描来源") {
                    viewModel.refreshSkills()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "#495057"))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color(hex: "#f1f3f5"))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#e9ecef"), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private func row(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(hex: "#adb5bd"))
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#495057"))
                .textSelection(.enabled)
        }
    }
}
