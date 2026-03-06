import SwiftUI

struct SkillCardView: View {
    let skill: Skill
    let appName: String
    let onRemove: () -> Void
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
                Button("移除") {
                    onRemove()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "#adb5bd"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isHovering ? Color(hex: "#fff5f5") : .clear)
                .cornerRadius(8)
            }

            Text(skill.description)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#868e96"))
                .lineLimit(2)

            HStack {
                Text(appName)
                    .font(.system(size: 11))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#e7f5ff"))
                    .foregroundColor(Color(hex: "#4c6ef5"))
                    .clipShape(Capsule())
                Spacer()
                Button("详情 →") {
                    onDetails()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: UIStyleConstants.primaryColorHex))
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
}
