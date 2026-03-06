import SwiftUI

struct SourceFilterView: View {
    let sources: [Source]
    let selectedSourceID: UUID?
    let counts: [UUID: Int]
    let allCount: Int
    let onSelect: (UUID?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                tag(title: "全部", count: allCount, isActive: selectedSourceID == nil) {
                    onSelect(nil)
                }
                ForEach(sources) { source in
                    tag(
                        title: source.displayName,
                        count: counts[source.id] ?? 0,
                        isActive: selectedSourceID == source.id
                    ) {
                        onSelect(source.id)
                    }
                }
            }
        }
    }

    private func tag(title: String, count: Int, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .lineLimit(1)
                Text("\(count)")
                    .font(.system(size: 11))
                    .opacity(0.7)
            }
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(isActive ? Color(hex: "#e7f5ff") : Color(hex: "#f1f3f5"))
            .foregroundColor(isActive ? Color(hex: "#4c6ef5") : Color(hex: "#868e96"))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isActive ? Color(hex: "#4c6ef5") : .clear, lineWidth: 1)
            )
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}
