import XCTest
@testable import SkillDock

@MainActor
final class ProjectsFlowTests: XCTestCase {
    func testLoadPurgesLegacyProjectKeysFromPersistence() throws {
        let (userDefaults, suiteName) = makeUserDefaults()
        seedLegacyProjectPayload(userDefaults: userDefaults, path: "/tmp/demo")

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let configManager = ConfigManager(userDefaults: userDefaults)
        let viewModel = MainViewModel(
            configManager: configManager,
            skillScanner: SkillScanner(),
            fileService: FileService(),
            autoLoad: false
        )
        viewModel.load()

        let raw = try rawAppConfig(userDefaults: userDefaults)
        XCTAssertNil(raw["projects"])
        XCTAssertNil(raw["selectedProjectID"])
    }

    func testAddSourceStillPurgesLegacyProjectKeys() throws {
        let (userDefaults, suiteName) = makeUserDefaults()
        let sourceRoot = try makeTempDirectory()
        seedLegacyProjectPayload(userDefaults: userDefaults, path: sourceRoot.path)

        defer {
            try? FileManager.default.removeItem(at: sourceRoot)
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let configManager = ConfigManager(userDefaults: userDefaults)
        let viewModel = MainViewModel(
            configManager: configManager,
            skillScanner: SkillScanner(),
            fileService: FileService(),
            autoLoad: false
        )
        viewModel.load()
        XCTAssertTrue(viewModel.addSource(path: sourceRoot.path))

        let raw = try rawAppConfig(userDefaults: userDefaults)
        XCTAssertNil(raw["projects"])
        XCTAssertNil(raw["selectedProjectID"])
    }

    private func makeUserDefaults() -> (UserDefaults, String) {
        let suiteName = "ProjectsFlowTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            fatalError("unable to create user defaults suite")
        }
        userDefaults.removePersistentDomain(forName: suiteName)
        return (userDefaults, suiteName)
    }
    private func makeTempDirectory() throws -> URL {
        let base = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let target = base.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        return target
    }

    private func seedLegacyProjectPayload(userDefaults: UserDefaults, path: String) {
        let payload = """
        {
          "projects": [
            {
              "id": "D57E26AF-F40A-4909-BC2E-6FCF2A3D79F6",
              "isFavorite": true,
              "name": "legacy",
              "path": "\(path)",
              "updatedAt": "2026-03-04T10:00:00Z"
            }
          ],
          "selectedProjectID": "D57E26AF-F40A-4909-BC2E-6FCF2A3D79F6",
          "skillStates": {
            "\(path)#brainstorming": true
          },
          "sources": []
        }
        """
        userDefaults.set(Data(payload.utf8), forKey: "skilldock.appConfig")
    }

    private func rawAppConfig(userDefaults: UserDefaults) throws -> [String: Any] {
        guard let data = userDefaults.data(forKey: "skilldock.appConfig") else {
            XCTFail("missing raw app config")
            return [:]
        }
        let object = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = object as? [String: Any] else {
            XCTFail("invalid raw app config")
            return [:]
        }
        return dictionary
    }
}
