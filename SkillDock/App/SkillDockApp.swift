import SwiftUI

@main
struct SkillDockApp: App {
    @StateObject private var viewModel: MainViewModel = {
        let processInfo = ProcessInfo.processInfo
        let arguments = Set(processInfo.arguments)
        let viewModel: MainViewModel
        if arguments.contains("-uitest_mode") {
            let root = processInfo.environment["UITEST_SKILLS_ROOT"]
                ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                .appendingPathComponent("skilldock-uitest-installed", isDirectory: true)
                .path
            for app in AppTarget.allCases {
                let path = URL(fileURLWithPath: root, isDirectory: true)
                    .appendingPathComponent(app.rawValue, isDirectory: true)
                try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
            }
            viewModel = MainViewModel(
                appSkillsPathResolver: { app in
                    URL(fileURLWithPath: root, isDirectory: true)
                        .appendingPathComponent(app.rawValue, isDirectory: true)
                        .path
                }
            )
        } else {
            viewModel = MainViewModel()
        }
        viewModel.applyUITestOverridesIfNeeded(processInfo: processInfo)
        return viewModel
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .preferredColorScheme(preferredColorScheme)
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch viewModel.themeMode {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
