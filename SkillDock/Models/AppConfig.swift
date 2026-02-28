import Foundation

enum AppTarget: String, Codable, CaseIterable, Identifiable {
    case claudeCode
    case codex
    case trae
    case traeCN

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claudeCode:
            return "Claude Code"
        case .codex:
            return "Codex"
        case .trae:
            return "Trae"
        case .traeCN:
            return "Trae CN"
        }
    }
}

struct AppConfig: Codable, Equatable {
    var sources: [Source]
    var projects: [Project]
    var selectedProjectID: UUID?
    var selectedAppTarget: AppTarget

    init(
        sources: [Source] = [],
        projects: [Project] = [],
        selectedProjectID: UUID? = nil,
        selectedAppTarget: AppTarget = .claudeCode
    ) {
        self.sources = sources
        self.projects = projects
        self.selectedProjectID = selectedProjectID
        self.selectedAppTarget = selectedAppTarget
    }

    static let `default` = AppConfig()
}
