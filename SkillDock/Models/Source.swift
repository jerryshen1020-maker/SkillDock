import Foundation

enum SourceType: String, Codable, CaseIterable, Identifiable {
    case local
    case git

    var id: String { rawValue }
}

struct Source: Identifiable, Codable, Equatable {
    let id: UUID
    let path: String
    let displayName: String
    let addedAt: Date
    let type: SourceType
    let repoURL: String?
    let branch: String?
    let isAvailable: Bool
    let lastError: String?
    let isBuiltIn: Bool

    init(
        id: UUID = UUID(),
        path: String,
        displayName: String,
        addedAt: Date = Date(),
        type: SourceType = .local,
        repoURL: String? = nil,
        branch: String? = nil,
        isAvailable: Bool = true,
        lastError: String? = nil,
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.path = path
        self.displayName = displayName
        self.addedAt = addedAt
        self.type = type
        self.repoURL = repoURL
        self.branch = branch
        self.isAvailable = isAvailable
        self.lastError = lastError
        self.isBuiltIn = isBuiltIn
    }
}

extension Source {
    func withAvailability(isAvailable: Bool, lastError: String?) -> Source {
        Source(
            id: id,
            path: path,
            displayName: displayName,
            addedAt: addedAt,
            type: type,
            repoURL: repoURL,
            branch: branch,
            isAvailable: isAvailable,
            lastError: lastError,
            isBuiltIn: isBuiltIn
        )
    }
}

extension Source {
    private enum CodingKeys: String, CodingKey {
        case id
        case path
        case displayName
        case addedAt
        case type
        case repoURL
        case branch
        case isAvailable
        case lastError
        case isBuiltIn
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        path = try container.decode(String.self, forKey: .path)
        displayName = try container.decode(String.self, forKey: .displayName)
        addedAt = try container.decode(Date.self, forKey: .addedAt)
        type = try container.decodeIfPresent(SourceType.self, forKey: .type) ?? .local
        repoURL = try container.decodeIfPresent(String.self, forKey: .repoURL)
        branch = try container.decodeIfPresent(String.self, forKey: .branch)
        isAvailable = try container.decodeIfPresent(Bool.self, forKey: .isAvailable) ?? true
        lastError = try container.decodeIfPresent(String.self, forKey: .lastError)
        isBuiltIn = try container.decodeIfPresent(Bool.self, forKey: .isBuiltIn) ?? false
    }
}
