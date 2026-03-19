import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var viewModel: MainViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 6) {
                ForEach(AppTarget.allCases) { app in
                    Button {
                        viewModel.selectApp(app)
                    } label: {
                        HStack(spacing: 8) {
                            Image(app.iconAssetName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            Text(app.displayName)
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                            Spacer(minLength: 8)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(viewModel.selectedApp == app ? Color(hex: "#e7f5ff") : Color(hex: "#f1f3f5"))
                        .foregroundColor(viewModel.selectedApp == app ? Color(hex: "#4c6ef5") : Color(hex: "#868e96"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(viewModel.selectedApp == app ? Color(hex: "#4c6ef5") : .clear, lineWidth: 1)
                        )
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isLoadingInstalledSkills)
                    .accessibilityIdentifier("app-target-\(app.rawValue)")
                    .handCursorOnHover()
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: 2) {
                SidebarEntryView(
                    icon: "folder.fill.badge.gearshape",
                    title: viewModel.localized(key: "sidebar.sources", chinese: "来源管理", english: "Sources"),
                    badge: viewModel.sources.count,
                    isActive: viewModel.selectedTab == .sourceManagement,
                    accessibilityIdentifier: "sidebar-source-management"
                ) {
                    viewModel.selectTab(.sourceManagement)
                }
                
                SidebarEntryView(
                    icon: "gearshape.fill",
                    title: viewModel.localized(key: "sidebar.settings", chinese: "设置", english: "Settings"),
                    badge: nil,
                    isActive: viewModel.selectedTab == .settings,
                    accessibilityIdentifier: "sidebar-settings"
                ) {
                    viewModel.selectTab(.settings)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 16)
        .frame(minWidth: UIStyleConstants.sidebarWidth, maxWidth: UIStyleConstants.sidebarWidth, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color(hex: "#dee2e6"))
                .frame(width: 1)
        }
    }
}
