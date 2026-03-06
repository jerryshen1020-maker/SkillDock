import XCTest
@testable import SkillDock

final class SkillScannerTests: XCTestCase {
    func testScanDirectoryReturnsOnlyFoldersContainingSkillFile() throws {
        let tempRoot = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        try makeSkillFolder(root: tempRoot, folderName: "brainstorming", name: "brainstorming", description: "Idea workflow")
        try makeSkillFolder(root: tempRoot, folderName: "writing-assistant", name: "writing-assistant", description: "")

        let notASkillFolder = tempRoot.appendingPathComponent("notes", isDirectory: true)
        try FileManager.default.createDirectory(at: notASkillFolder, withIntermediateDirectories: true)
        try "no skill file".write(to: notASkillFolder.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)

        let scanner = SkillScanner()
        let skills = try scanner.scanDirectory(tempRoot.path, sourceID: UUID())

        XCTAssertEqual(skills.count, 2)
        XCTAssertEqual(skills.map(\.folderName).sorted(), ["brainstorming", "writing-assistant"])
        XCTAssertEqual(skills.first(where: { $0.folderName == "writing-assistant" })?.description, "暂无描述")
    }

    func testScanDirectoryRecursivelyFindsNestedSkillFolders() throws {
        let tempRoot = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let nestedFolder = tempRoot
            .appendingPathComponent("categories", isDirectory: true)
            .appendingPathComponent("brainstorming", isDirectory: true)
        try FileManager.default.createDirectory(at: nestedFolder, withIntermediateDirectories: true)
        try """
        ---
        name: brainstorming
        description: nested skill
        ---
        """.write(
            to: nestedFolder.appendingPathComponent("SKILL.md"),
            atomically: true,
            encoding: .utf8
        )

        let scanner = SkillScanner()
        let skills = try scanner.scanDirectory(tempRoot.path, sourceID: UUID())

        XCTAssertEqual(skills.count, 1)
        XCTAssertEqual(skills.first?.folderName, "categories/brainstorming")
    }

    private func makeTempDirectory() throws -> URL {
        let base = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let target = base.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        return target
    }

    private func makeSkillFolder(root: URL, folderName: String, name: String, description: String) throws {
        let folderURL = root.appendingPathComponent(folderName, isDirectory: true)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

        let skillContent = """
        ---
        name: \(name)
        description: \(description)
        ---
        body
        """
        try skillContent.write(to: folderURL.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
    }
}
