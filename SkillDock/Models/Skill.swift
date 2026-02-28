import Foundation

struct Skill: Identifiable, Codable, Hashable {
    let id: String
    let folderName: String
    let name: String
    let description: String
    let sourceID: UUID
    let sourcePath: String
    let fullPath: String
    var isEnabled: Bool

    init(
        folderName: String,
        name: String,
        description: String,
        sourceID: UUID,
        sourcePath: String,
        fullPath: String,
        isEnabled: Bool = true
    ) {
        self.folderName = folderName
        self.name = name
        self.description = description.isEmpty ? "暂无描述" : description
        self.sourceID = sourceID
        self.sourcePath = sourcePath
        self.fullPath = fullPath
        self.id = Skill.makeID(sourcePath: sourcePath, folderName: folderName)
        self.isEnabled = isEnabled
    }

    static func makeID(sourcePath: String, folderName: String) -> String {
        "\(sourcePath)#\(folderName)"
    }
}
