import Foundation

struct Source: Identifiable, Codable, Equatable {
    let id: UUID
    let path: String
    let displayName: String
    let addedAt: Date
    let isBuiltIn: Bool

    init(
        id: UUID = UUID(),
        path: String,
        displayName: String,
        addedAt: Date = Date(),
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.path = path
        self.displayName = displayName
        self.addedAt = addedAt
        self.isBuiltIn = isBuiltIn
    }
}
