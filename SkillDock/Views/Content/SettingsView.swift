import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: MainViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                languageCard
                syncCard
            }
            .padding(24)
            .frame(maxWidth: 640, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(hex: "#fafbfc"))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(t("settings.title", "设置", "Settings"))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(hex: "#212529"))
            Text(t("settings.subtitle", "在这里查看当前应用目录、切换语言并执行基础维护操作。", "Manage app directory, switch language, and run basic maintenance here."))
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#868e96"))
        }
    }

    private var languageCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(t("settings.language.title", "界面语言", "Language"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "#212529"))
            Text(t("settings.language.subtitle", "选择后立即生效，并自动保存到本地配置。", "Takes effect immediately and is persisted locally."))
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#868e96"))
            HStack(spacing: 8) {
                languageButton(title: "English", language: .english)
                languageButton(title: "简体中文", language: .chinese)
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#e9ecef"), lineWidth: 1)
        )
        .cornerRadius(12)
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
    }

    private var syncCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(t("settings.sync.title", "同步与目录", "Sync & Directory"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "#212529"))
            row(label: t("settings.currentApp", "当前应用", "Current App"), value: viewModel.selectedAppName)
            row(label: t("settings.targetDirectory", "目标目录", "Target Directory"), value: viewModel.selectedAppSkillsPath)
            HStack(spacing: 8) {
                Button(t("settings.action.revealInFinder", "在 Finder 中显示目录", "Reveal in Finder")) {
                    FileService().revealInFinder(viewModel.selectedAppSkillsPath)
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "#364fc7"))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color(hex: "#edf2ff"))
                .cornerRadius(8)
                .handCursorOnHover()
                Button(t("settings.action.rescanSources", "重新扫描来源", "Rescan Sources")) {
                    viewModel.refreshSkills()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "#495057"))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color(hex: "#f1f3f5"))
                .cornerRadius(8)
                .handCursorOnHover()
            }
        }
        .padding(16)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#e9ecef"), lineWidth: 1)
        )
        .cornerRadius(12)
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
    }

    private func languageButton(title: String, language: Language) -> some View {
        let isSelected = viewModel.language == language
        return Button {
            viewModel.setLanguage(language)
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

    private func t(_ chinese: String, _ english: String) -> String {
        viewModel.localized(chinese: chinese, english: english)
    }

    private func t(_ key: String, _ chinese: String, _ english: String) -> String {
        viewModel.localized(key: key, chinese: chinese, english: english)
    }
}
