import Foundation

enum AppTarget: String, Codable, CaseIterable, Identifiable {
    case claudeCode
    case codex
    case openCode
    case trae
    case traeCN

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claudeCode: return "Claude Code"
        case .codex: return "Codex"
        case .openCode: return "OpenCode"
        case .trae: return "Trae"
        case .traeCN: return "Trae CN"
        }
    }

    var iconName: String {
        switch self {
        case .claudeCode: return "bubble.left.and.bubble.right.fill"
        case .codex: return "chevron.left.forwardslash.chevron.right"
        case .openCode: return "curlybraces"
        case .trae: return "bolt.horizontal.fill"
        case .traeCN: return "character.book.closed.fill"
        }
    }

    var defaultSkillsPath: String {
        switch self {
        case .claudeCode: return "~/.claude/skills/"
        case .codex: return "~/.codex/skills/"
        case .openCode: return "~/.config/opencode/skills/"
        case .trae: return "~/.trae/skills/"
        case .traeCN: return "~/.trae-cn/skills/"
        }
    }
}

enum NavigationPage: String, Codable, CaseIterable, Identifiable {
    case skills
    case sourceManagement
    case settings

    var id: String { rawValue }
}

enum ThemeMode: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
}

struct AppConfig: Codable, Equatable {
    var sources: [Source]
    var selectedApp: AppTarget
    var selectedPage: NavigationPage
    var themeMode: ThemeMode
    var legacySkillStates: [String: Bool]

    var skillStates: [String: Bool] {
        get { legacySkillStates }
        set { legacySkillStates = newValue }
    }

    init(
        sources: [Source] = [],
        selectedApp: AppTarget = .claudeCode,
        selectedPage: NavigationPage = .skills,
        themeMode: ThemeMode = .system,
        legacySkillStates: [String: Bool] = [:]
    ) {
        self.sources = sources
        self.selectedApp = selectedApp
        self.selectedPage = selectedPage
        self.themeMode = themeMode
        self.legacySkillStates = legacySkillStates
    }

    static let `default` = AppConfig()
}

extension AppConfig {
    private enum CodingKeys: String, CodingKey {
        case sources
        case selectedApp
        case selectedPage
        case themeMode
        case legacySkillStates
        case selectedAppTarget
        case skillStates
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sources = try container.decodeIfPresent([Source].self, forKey: .sources) ?? []
        selectedApp = try container.decodeIfPresent(AppTarget.self, forKey: .selectedApp)
            ?? container.decodeIfPresent(AppTarget.self, forKey: .selectedAppTarget)
            ?? .claudeCode
        selectedPage = try container.decodeIfPresent(NavigationPage.self, forKey: .selectedPage) ?? .skills
        themeMode = try container.decodeIfPresent(ThemeMode.self, forKey: .themeMode) ?? .system
        legacySkillStates = try container.decodeIfPresent([String: Bool].self, forKey: .legacySkillStates)
            ?? container.decodeIfPresent([String: Bool].self, forKey: .skillStates)
            ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sources, forKey: .sources)
        try container.encode(selectedApp, forKey: .selectedApp)
        try container.encode(selectedPage, forKey: .selectedPage)
        try container.encode(themeMode, forKey: .themeMode)
        try container.encode(legacySkillStates, forKey: .legacySkillStates)
        try container.encode(legacySkillStates, forKey: .skillStates)
    }
}
