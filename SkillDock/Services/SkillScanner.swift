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
        let enumerator = fileManager.enumerator(
            at: sourceURL,
            includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey, .isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )

        var skills: [Skill] = []
        var existingFolderNames: Set<String> = []
        let candidateRoots = rootCandidates(for: sourcePath)

        while let value = enumerator?.nextObject() as? URL {
            if value.lastPathComponent == "SKILL.md" {
                let skillFolderURL = value.deletingLastPathComponent()
                var folderName = relativeFolderName(skillFolderPath: skillFolderURL.path, rootCandidates: candidateRoots)
                if folderName.hasPrefix("/") {
                    folderName.removeFirst()
                }
                if folderName.isEmpty {
                    folderName = skillFolderURL.lastPathComponent
                }

                let metadata = try metadataParser.parseFile(at: value, fallbackName: folderName)
                let skill = Skill(
                    folderName: folderName,
                    name: metadata.name,
                    description: metadata.description,
                    sourceID: sourceID,
                    sourcePath: sourcePath,
                    fullPath: skillFolderURL.path
                )
                skills.append(skill)
                existingFolderNames.insert(folderName)
                continue
            }

            let values = try? value.resourceValues(forKeys: [.isSymbolicLinkKey, .isDirectoryKey])
            guard values?.isSymbolicLink == true else { continue }
            let resolvedPath = try resolvedSymlinkDestination(at: value.path)
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: resolvedPath, isDirectory: &isDirectory), isDirectory.boolValue else {
                continue
            }
            let resolvedURL = URL(fileURLWithPath: resolvedPath, isDirectory: true)
            let skillFileURL = resolvedURL.appendingPathComponent("SKILL.md", isDirectory: false)
            guard fileManager.fileExists(atPath: skillFileURL.path) else { continue }

            var folderName = relativeFolderName(skillFolderPath: value.path, rootCandidates: candidateRoots)
            if folderName.hasPrefix("/") {
                folderName.removeFirst()
            }
            if folderName.isEmpty {
                folderName = value.lastPathComponent
            }
            if existingFolderNames.contains(folderName) {
                continue
            }
            let metadata = try metadataParser.parseFile(at: skillFileURL, fallbackName: folderName)
            let skill = Skill(
                folderName: folderName,
                name: metadata.name,
                description: metadata.description,
                sourceID: sourceID,
                sourcePath: sourcePath,
                fullPath: resolvedURL.path
            )
            skills.append(skill)
            existingFolderNames.insert(folderName)
        }

        let topLevelItems = try fileManager.contentsOfDirectory(
            at: sourceURL,
            includingPropertiesForKeys: [.isSymbolicLinkKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        for item in topLevelItems {
            let values = try? item.resourceValues(forKeys: [.isSymbolicLinkKey, .isDirectoryKey])
            let isSymlink = values?.isSymbolicLink ?? false
            let isDirectory = values?.isDirectory ?? false
            if !isSymlink && !isDirectory {
                continue
            }
            let resolvedPath: String
            if isSymlink {
                resolvedPath = try resolvedSymlinkDestination(at: item.path)
            } else {
                resolvedPath = item.path
            }
            let resolvedURL = URL(fileURLWithPath: resolvedPath, isDirectory: true)
            let skillFileURL = resolvedURL.appendingPathComponent("SKILL.md", isDirectory: false)
            guard fileManager.fileExists(atPath: skillFileURL.path) else { continue }
            let folderName = item.lastPathComponent
            if existingFolderNames.contains(folderName) {
                continue
            }
            let metadata = try metadataParser.parseFile(at: skillFileURL, fallbackName: folderName)
            let skill = Skill(
                folderName: folderName,
                name: metadata.name,
                description: metadata.description,
                sourceID: sourceID,
                sourcePath: sourcePath,
                fullPath: resolvedURL.path
            )
            skills.append(skill)
            existingFolderNames.insert(folderName)
        }

        return skills.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func relativeFolderName(skillFolderPath: String, rootCandidates: [String]) -> String {
        for root in rootCandidates where skillFolderPath == root || skillFolderPath.hasPrefix(root + "/") {
            return String(skillFolderPath.dropFirst(root.count))
        }
        return skillFolderPath
    }

    private func rootCandidates(for sourcePath: String) -> [String] {
        var candidates: [String] = []
        let normalized = URL(fileURLWithPath: sourcePath, isDirectory: true).path
        candidates.append(normalized)
        let resolved = URL(fileURLWithPath: sourcePath, isDirectory: true).resolvingSymlinksInPath().path
        if !resolved.isEmpty {
            candidates.append(resolved)
        }
        if normalized.hasPrefix("/var/") {
            candidates.append("/private" + normalized)
        }
        if normalized.hasPrefix("/private/var/") {
            candidates.append(String(normalized.dropFirst("/private".count)))
        }
        var seen = Set<String>()
        return candidates.filter { seen.insert($0).inserted }
    }

    private func resolvedSymlinkDestination(at path: String) throws -> String {
        let rawDestination = try fileManager.destinationOfSymbolicLink(atPath: path)
        if rawDestination.hasPrefix("/") {
            return URL(fileURLWithPath: rawDestination).standardizedFileURL.path
        }
        let baseURL = URL(fileURLWithPath: path).deletingLastPathComponent()
        return baseURL.appendingPathComponent(rawDestination).standardizedFileURL.path
    }
}
