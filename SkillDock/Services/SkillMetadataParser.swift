import Foundation

struct SkillMetadata: Equatable {
    let name: String
    let description: String
}

final class SkillMetadataParser {
    func parseFile(at fileURL: URL, fallbackName: String) throws -> SkillMetadata {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        return parse(content: content, fallbackName: fallbackName)
    }

    func parse(content: String, fallbackName: String) -> SkillMetadata {
        let frontmatter = extractFrontmatter(from: content)
        let parsedName = frontmatter["name"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedDescription = frontmatter["description"]?.trimmingCharacters(in: .whitespacesAndNewlines)

        let name = (parsedName?.isEmpty == false) ? parsedName! : fallbackName
        let description = (parsedDescription?.isEmpty == false) ? parsedDescription! : "暂无描述"
        return SkillMetadata(name: name, description: description)
    }

    private func extractFrontmatter(from content: String) -> [String: String] {
        let lines = content.components(separatedBy: .newlines)
        guard lines.first == "---" else { return [:] }

        var fields: [String: String] = [:]
        for line in lines.dropFirst() {
            if line == "---" { break }
            guard let separatorIndex = line.firstIndex(of: ":") else { continue }
            let key = String(line[..<separatorIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            let valueStart = line.index(after: separatorIndex)
            var value = String(line[valueStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
            value = trimWrappingQuotes(value)
            fields[key] = value
        }
        return fields
    }

    private func trimWrappingQuotes(_ value: String) -> String {
        guard value.count >= 2 else { return value }
        if (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
            return String(value.dropFirst().dropLast())
        }
        return value
    }
}
