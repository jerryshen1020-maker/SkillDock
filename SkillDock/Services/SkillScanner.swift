import Foundation

final class SkillScanner {
    private let fileManager: FileManager
    private let metadataParser: SkillMetadataParser

    init(
        fileManager: FileManager = .default,
        metadataParser: SkillMetadataParser = SkillMetadataParser()
    ) {
        self.fileManager = fileManager
        self.metadataParser = metadataParser
    }

    func scanDirectory(_ sourcePath: String, sourceID: UUID) throws -> [Skill] {
        let sourceURL = URL(fileURLWithPath: sourcePath, isDirectory: true)
        let entries = try fileManager.contentsOfDirectory(
            at: sourceURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        var skills: [Skill] = []
        for entry in entries {
            let values = try entry.resourceValues(forKeys: [.isDirectoryKey])
            guard values.isDirectory == true else { continue }

            let folderName = entry.lastPathComponent
            let skillFileURL = entry.appendingPathComponent("SKILL.md")
            guard fileManager.fileExists(atPath: skillFileURL.path) else { continue }

            let metadata = try metadataParser.parseFile(at: skillFileURL, fallbackName: folderName)
            let skill = Skill(
                folderName: folderName,
                name: metadata.name,
                description: metadata.description,
                sourceID: sourceID,
                sourcePath: sourcePath,
                fullPath: entry.path
            )
            skills.append(skill)
        }

        return skills.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
