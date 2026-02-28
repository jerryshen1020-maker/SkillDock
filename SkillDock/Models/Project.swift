import Foundation

struct Project: Identifiable, Codable, Equatable {
    let id: UUID
    let path: String
    let name: String
    var isFavorite: Bool
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        path: String,
        name: String,
        isFavorite: Bool = false,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.path = path
        self.name = name
        self.isFavorite = isFavorite
        self.updatedAt = updatedAt
    }
}
