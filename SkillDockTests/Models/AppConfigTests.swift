import XCTest
@testable import SkillDock

final class AppConfigTests: XCTestCase {
    func testAppConfigCodableRoundTrip() throws {
        let source = Source(
            path: "/tmp/skills",
            displayName: "skills",
            type: .git,
            repoURL: "https://example.com/repo.git",
            branch: "main",
            isAvailable: true
        )
        let config = AppConfig(
            sources: [source],
            selectedApp: .codex,
            selectedPage: .sourceManagement,
            themeMode: .dark,
            legacySkillStates: ["x#brainstorming": true]
        )

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(AppConfig.self, from: data)

        XCTAssertEqual(decoded, config)
    }

    func testAppConfigDecodesLegacyV11Payload() throws {
        let legacyJSON = """
        {
          "projects": [
            {
              "id": "D57E26AF-F40A-4909-BC2E-6FCF2A3D79F6",
              "isFavorite": true,
              "name": "demo",
              "path": "/tmp/demo",
              "updatedAt": "2026-03-04T10:00:00Z"
            }
          ],
          "selectedProjectID": "D57E26AF-F40A-4909-BC2E-6FCF2A3D79F6",
          "skillStates": {
            "/tmp/skills#brainstorming": true
          },
          "sources": [
            {
              "addedAt": "2026-03-04T10:00:00Z",
              "displayName": "skills",
              "id": "8AF4EDB8-C304-4066-B512-6F1D30E74F9B",
              "isBuiltIn": false,
              "path": "/tmp/skills"
            }
          ]
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let config = try decoder.decode(AppConfig.self, from: Data(legacyJSON.utf8))

        XCTAssertEqual(config.selectedApp, .claudeCode)
        XCTAssertEqual(config.selectedPage, .skills)
        XCTAssertEqual(config.themeMode, .system)
        XCTAssertEqual(config.sources.count, 1)
        XCTAssertEqual(config.legacySkillStates["/tmp/skills#brainstorming"], true)
        XCTAssertEqual(config.sources.first?.type, .local)
        XCTAssertNil(config.sources.first?.repoURL)
        XCTAssertNil(config.sources.first?.branch)
        XCTAssertEqual(config.sources.first?.isAvailable, true)
        XCTAssertNil(config.sources.first?.lastError)
    }

    func testSkillIDUsesSourcePathAndFolderName() {
        let id = Skill.makeID(sourcePath: "/a/b", folderName: "brainstorming")

        XCTAssertEqual(id, "/a/b#brainstorming")
    }
}
