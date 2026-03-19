import SwiftUI

struct SkillCardView: View {
    enum ActionStyle {
        case install
        case remove
        case installed
    }

    let skill: Skill
    let contextLabel: String
    let actionTitle: String
    let actionStyle: ActionStyle
    let isActionEnabled: Bool
    let detailsTitle: String
    let onAction: () -> Void
    let onDetails: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#e7f5ff"))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: UIStyleConstants.primaryColorHex))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(skill.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "#212529"))
                        .lineLimit(1)
                    Text(skill.sourcePath)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#adb5bd"))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
                Button(actionTitle) {
                    onAction()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(actionForegroundColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(actionBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(actionBorderColor, lineWidth: 1)
                )
                .cornerRadius(8)
                .disabled(!isActionEnabled)
                .handCursorOnHover()
            }

            Text(skill.description)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#868e96"))
                .lineLimit(2)

            HStack {
                Text(contextLabel)
                    .font(.system(size: 11))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#e7f5ff"))
                    .foregroundColor(Color(hex: "#4c6ef5"))
                    .clipShape(Capsule())
                Spacer()
                Button(detailsTitle) {
                    onDetails()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: UIStyleConstants.primaryColorHex))
                .handCursorOnHover()
            }
        }
        .padding(16)
        .frame(minHeight: 145)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: UIStyleConstants.skillCardCornerRadius)
                .stroke(isHovering ? Color(hex: UIStyleConstants.primaryColorHex) : Color(hex: "#f1f3f5"), lineWidth: 1)
        )
        .shadow(color: isHovering ? Color.black.opacity(0.06) : .clear, radius: 12, x: 0, y: 4)
        .cornerRadius(UIStyleConstants.skillCardCornerRadius)
        .offset(y: isHovering ? -2 : 0)
        .animation(.easeOut(duration: 0.18), value: isHovering)
        .onHover { isHovering = $0 }
    }

    private var actionForegroundColor: Color {
        if !isActionEnabled {
            return Color(hex: "#adb5bd")
        }
        switch actionStyle {
        case .install:
            return .white
        case .remove:
            return Color(hex: "#e03131")
        case .installed:
            return Color(hex: "#495057")
        }
    }

    private var actionBackgroundColor: Color {
        if !isActionEnabled {
            return Color(hex: "#f1f3f5")
        }
        switch actionStyle {
        case .install:
            return isHovering ? Color(hex: "#364fc7") : Color(hex: "#4c6ef5")
        case .remove:
            return isHovering ? Color(hex: "#ffe3e3") : Color(hex: "#fff5f5")
        case .installed:
            return Color(hex: "#f1f3f5")
        }
    }

    private var actionBorderColor: Color {
        if !isActionEnabled {
            return Color(hex: "#e9ecef")
        }
        switch actionStyle {
        case .install:
            return Color(hex: "#4c6ef5")
        case .remove:
            return Color(hex: "#ffc9c9")
        case .installed:
            return Color(hex: "#dee2e6")
        }
    }
}
