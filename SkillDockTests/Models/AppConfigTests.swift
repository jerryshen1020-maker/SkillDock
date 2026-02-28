import XCTest
@testable import SkillDock

final class AppConfigTests: XCTestCase {
    func testAppConfigCodableRoundTrip() throws {
        let source = Source(path: "/tmp/skills", displayName: "skills")
        let project = Project(path: "/tmp/demo", name: "demo", isFavorite: true)
        let config = AppConfig(
            sources: [source],
            projects: [project],
            selectedProjectID: project.id,
            selectedAppTarget: .codex
        )

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(AppConfig.self, from: data)

        XCTAssertEqual(decoded, config)
    }

    func testProjectSkillConfigDefaultVersion() {
        XCTAssertEqual(ProjectSkillConfig.default.version, "1.0")
        XCTAssertTrue(ProjectSkillConfig.default.appTargets.isEmpty)
    }

    func testSkillIDUsesSourcePathAndFolderName() {
        let id = Skill.makeID(sourcePath: "/a/b", folderName: "brainstorming")

        XCTAssertEqual(id, "/a/b#brainstorming")
    }
}
