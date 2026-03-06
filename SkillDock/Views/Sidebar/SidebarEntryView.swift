import SwiftUI

struct SidebarEntryView: View {
    let icon: String
    let title: String
    let badge: Int?
    let isActive: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 16, height: 16)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Spacer(minLength: 8)
                if let badge {
                    Text("\(badge)")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isActive ? Color(hex: "#4c6ef5") : Color(hex: "#f1f3f5"))
                        .foregroundColor(isActive ? .white : Color(hex: "#adb5bd"))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }

    private var backgroundColor: Color {
        if isActive {
            return Color(hex: "#e7f5ff")
        }
        if isHovering {
            return Color(hex: "#e9ecef")
        }
        return Color(hex: "#f1f3f5")
    }

    private var foregroundColor: Color {
        if isActive {
            return Color(hex: "#4c6ef5")
        }
        if isHovering {
            return Color(hex: "#212529")
        }
        return Color(hex: "#868e96")
    }
}
