import SwiftUI

struct SkillDetailView: View {
    let skill: Skill
    let onRevealInFinder: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                Button("关闭") {
                    onClose()
                }
            }

            Text(skill.name)
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 6) {
                Text("Description")
                    .font(.headline)
                Text(skill.description)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("来源目录")
                    .font(.headline)
                Text(skill.fullPath)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            HStack {
                Button("在 Finder 中显示") {
                    onRevealInFinder()
                }
                Spacer()
            }
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 320, alignment: .topLeading)
    }
}

