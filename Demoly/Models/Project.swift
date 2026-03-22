//
//  Project.swift
//  Demoly
//

import Foundation

nonisolated struct Project: Identifiable, Equatable, Hashable, @unchecked Sendable {
    let id: String
    let userId: String
    var title: String
    var description: String?
    var htmlContent: String?
    var cssContent: String?
    var jsContent: String?
    var thumbnailUrl: String?
    /// Stored for backend compatibility; display uses `Thumbnail.aspectRatio`.
    var thumbnailAspectRatio: CGFloat?
    var tags: [String]?
    var chatMessages: [[String: Any]]?
    var isPublished: Bool
    var viewCount: Int
    var likeCount: Int
    var collectCount: Int
    var commentCount: Int
    var shareCount: Int
    let createdAt: Date
    var updatedAt: Date

    var creator: Profile?

    var isLikedByCurrentUser: Bool?
    var isCollectedByCurrentUser: Bool?

    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.id == rhs.id && lhs.userId == rhs.userId && lhs.title == rhs.title && lhs.description == rhs.description
            && lhs.htmlContent == rhs.htmlContent && lhs.cssContent == rhs.cssContent && lhs.jsContent == rhs.jsContent
            && lhs.thumbnailUrl == rhs.thumbnailUrl && lhs.isPublished == rhs.isPublished && lhs.updatedAt == rhs.updatedAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    enum CodingKeys: String, CodingKey {
        case id, userId, title, description, htmlContent, cssContent, jsContent
        case thumbnailUrl, thumbnailAspectRatio, tags, chatMessages
        case isPublished, viewCount, likeCount, collectCount, commentCount, shareCount
        case createdAt, updatedAt, creator
        case isLikedByCurrentUser = "is_liked"
        case isCollectedByCurrentUser = "is_collected"
    }

    var displayTitle: String {
        title.isEmpty ? "Untitled" : title
    }

    func resolvedThumbnailURL() -> URL? {
        guard let thumbnailUrl else { return nil }
        if thumbnailUrl.hasPrefix("http") { return URL(string: thumbnailUrl) }
        let ts = Int(updatedAt.timeIntervalSince1970)
        return URL(string: "\(Config.hostURL)\(thumbnailUrl)?v=\(ts)")
    }
}

// MARK: - Codable

nonisolated extension Project: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)
        htmlContent = try container.decodeIfPresent(String.self, forKey: .htmlContent)
        cssContent = try container.decodeIfPresent(String.self, forKey: .cssContent)
        jsContent = try container.decodeIfPresent(String.self, forKey: .jsContent)
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        if let ratio = try container.decodeIfPresent(Double.self, forKey: .thumbnailAspectRatio) {
            thumbnailAspectRatio = CGFloat(ratio)
        } else {
            thumbnailAspectRatio = nil
        }
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        isPublished = try container.decodeIfPresent(Bool.self, forKey: .isPublished) ?? false
        viewCount = try container.decodeIfPresent(Int.self, forKey: .viewCount) ?? 0
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        collectCount = try container.decodeIfPresent(Int.self, forKey: .collectCount) ?? 0
        commentCount = try container.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0
        shareCount = try container.decodeIfPresent(Int.self, forKey: .shareCount) ?? 0
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        creator = try container.decodeIfPresent(Profile.self, forKey: .creator)
        isLikedByCurrentUser = try container.decodeIfPresent(Bool.self, forKey: .isLikedByCurrentUser)
        isCollectedByCurrentUser = try container.decodeIfPresent(Bool.self, forKey: .isCollectedByCurrentUser)

        if container.contains(.chatMessages) {
            if let rawMessages = try? container.decode([[String: AnyCodable]].self, forKey: .chatMessages) {
                chatMessages = rawMessages.map { dict in dict.mapValues { $0.value } }
            } else if let messagesString = try? container.decode(String.self, forKey: .chatMessages),
                let data = messagesString.data(using: .utf8),
                let messages = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            {
                chatMessages = messages
            } else {
                chatMessages = nil
            }
        } else {
            chatMessages = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(htmlContent, forKey: .htmlContent)
        try container.encodeIfPresent(cssContent, forKey: .cssContent)
        try container.encodeIfPresent(jsContent, forKey: .jsContent)
        try container.encodeIfPresent(thumbnailUrl, forKey: .thumbnailUrl)
        if let ratio = thumbnailAspectRatio {
            try container.encode(Double(ratio), forKey: .thumbnailAspectRatio)
        }
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encode(isPublished, forKey: .isPublished)
        try container.encode(viewCount, forKey: .viewCount)
        try container.encode(likeCount, forKey: .likeCount)
        try container.encode(collectCount, forKey: .collectCount)
        try container.encode(commentCount, forKey: .commentCount)
        try container.encode(shareCount, forKey: .shareCount)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(creator, forKey: .creator)
        try container.encodeIfPresent(isLikedByCurrentUser, forKey: .isLikedByCurrentUser)
        try container.encodeIfPresent(isCollectedByCurrentUser, forKey: .isCollectedByCurrentUser)

        if let messages = chatMessages {
            let codable = messages.map { $0.mapValues { AnyCodable($0) } }
            try container.encode(codable, forKey: .chatMessages)
        }
    }
}

// MARK: - AnyCodable

nonisolated struct AnyCodable: Codable, @unchecked Sendable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map(\.value)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues(\.value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull: try container.encodeNil()
        case let bool as Bool: try container.encode(bool)
        case let int as Int: try container.encode(int)
        case let double as Double: try container.encode(double)
        case let string as String: try container.encode(string)
        case let array as [Any]: try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]: try container.encode(dict.mapValues { AnyCodable($0) })
        default: throw EncodingError.invalidValue(value, .init(codingPath: encoder.codingPath, debugDescription: "Unable to encode value"))
        }
    }
}

// MARK: - Sample Data

extension Project {
    static let sample = Project(
        id: "sample-project-001",
        userId: Profile.sample.id,
        title: "Neon Pulse",
        description: "A mesmerizing neon animation",
        htmlContent: "<div class=\"container\"><div class=\"pulse\"></div><h1>Demoly</h1></div>",
        cssContent: ".container { display: flex; align-items: center; justify-content: center; height: 100vh; background: #1a1a2e; }",
        jsContent: nil,
        thumbnailUrl: nil,
        tags: ["animation", "neon", "css"],
        chatMessages: nil,
        isPublished: true,
        viewCount: 1234,
        likeCount: 567,
        collectCount: 45,
        commentCount: 89,
        shareCount: 23,
        createdAt: Date(),
        updatedAt: Date(),
        creator: Profile.sample
    )
}
