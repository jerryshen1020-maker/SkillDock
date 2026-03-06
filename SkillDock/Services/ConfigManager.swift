import Foundation

final class ConfigManager {
    private enum Keys {
        static let appConfig = "skilldock.appConfig"
    }
    private enum Files {
        static let claudeDirectory = ".claude"
        static let claudeSettings = "settings.json"
    }

    private let userDefaults: UserDefaults
    private let fileManager: FileManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard, fileManager: FileManager = .default) {
        self.userDefaults = userDefaults
        self.fileManager = fileManager
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func loadAppConfig() -> AppConfig {
        guard let data = userDefaults.data(forKey: Keys.appConfig) else {
            return .default
        }
        if let config = try? decoder.decode(AppConfig.self, from: data) {
            return config
        }
        if let migrated = migrateLegacyAppConfig(from: data) {
            saveAppConfig(migrated)
            return migrated
        }
        return .default
    }

    func saveAppConfig(_ config: AppConfig) {
        guard let data = try? encoder.encode(config) else { return }
        userDefaults.set(data, forKey: Keys.appConfig)
    }

    @discardableResult
    func syncClaudePermissions(projectPath: String, skills: [Skill], states: [String: Bool]) -> Bool {
        let projectURL = URL(fileURLWithPath: projectPath, isDirectory: true)
        let claudeDirURL = projectURL.appendingPathComponent(Files.claudeDirectory, isDirectory: true)
        let settingsURL = claudeDirURL.appendingPathComponent(Files.claudeSettings)

        do {
            if !fileManager.fileExists(atPath: claudeDirURL.path) {
                try fileManager.createDirectory(at: claudeDirURL, withIntermediateDirectories: true)
            }

            var root: [String: Any] = [:]
            if
                let data = try? Data(contentsOf: settingsURL),
                let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            {
                root = object
            }

            var permissions = root["permissions"] as? [String: Any] ?? [:]
            var allow = Set((permissions["allow"] as? [String] ?? []).map(normalizePermissionName))
            var deny = Set((permissions["deny"] as? [String] ?? []).map(normalizePermissionName))

            for skill in skills {
                let permission = claudeSkillPermission(for: skill.folderName)
                let enabled = states[skill.id] ?? true
                if enabled {
                    allow.insert(permission)
                    deny.remove(permission)
                } else {
                    deny.insert(permission)
                    allow.remove(permission)
                }
            }

            permissions["allow"] = Array(allow).sorted()
            permissions["deny"] = Array(deny).sorted()
            root["permissions"] = permissions

            let data = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: settingsURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    private func claudeSkillPermission(for folderName: String) -> String {
        "Skills:\(folderName)"
    }

    private func normalizePermissionName(_ permission: String) -> String {
        guard permission.lowercased().hasPrefix("skills:") else {
            return permission
        }
        return claudeSkillPermission(for: String(permission.dropFirst(7)))
    }

    private func migrateLegacyAppConfig(from data: Data) -> AppConfig? {
        guard let legacy = try? decoder.decode(LegacyAppConfig.self, from: data) else {
            return nil
        }
        return AppConfig(
            sources: legacy.sources,
            selectedApp: .claudeCode,
            selectedPage: .skills,
            themeMode: .system,
            legacySkillStates: legacy.skillStates
        )
    }
}

private struct LegacyAppConfig: Codable {
    var sources: [Source]
    var skillStates: [String: Bool]

    init(
        sources: [Source] = [],
        skillStates: [String: Bool] = [:]
    ) {
        self.sources = sources
        self.skillStates = skillStates
    }
}
