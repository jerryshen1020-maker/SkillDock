import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var viewModel: MainViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("应用")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "#adb5bd"))
                .textCase(.uppercase)
                .padding(.horizontal, 12)
                .padding(.top, 4)

            VStack(spacing: 6) {
                ForEach(AppTarget.allCases) { app in
                    Button {
                        viewModel.selectApp(app)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: app.iconName)
                                .font(.system(size: 13, weight: .medium))
                                .frame(width: 16, height: 16)
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
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: 2) {
                SidebarEntryView(
                    icon: "folder.fill.badge.gearshape",
                    title: SidebarTab.sourceManagement.rawValue,
                    badge: viewModel.sources.count,
                    isActive: viewModel.selectedTab == .sourceManagement
                ) {
                    viewModel.selectTab(.sourceManagement)
                }
                
                SidebarEntryView(
                    icon: "gearshape.fill",
                    title: SidebarTab.settings.rawValue,
                    badge: nil,
                    isActive: viewModel.selectedTab == .settings
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
