import Foundation

struct ProjectSkillConfig: Codable, Equatable {
    var version: String
    var appTargets: [AppTarget: [String: Bool]]

    init(version: String = "1.0", appTargets: [AppTarget: [String: Bool]] = [:]) {
        self.version = version
        self.appTargets = appTargets
    }

    static let `default` = ProjectSkillConfig()
}
