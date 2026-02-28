import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: MainViewModel

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Skills仓库")) {
                    Text("全部技能")
                }
                Section(header: Text("项目")) {
                    Text("全部项目")
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("SkillDock")

            VStack(alignment: .leading, spacing: 12) {
                Text("SkillDock")
                    .font(.title2.bold())
                Text("准备开发中：基础框架已就绪")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(MainViewModel())
}
