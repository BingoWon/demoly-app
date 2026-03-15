//
//  Profile.swift
//  Swipop
//

import Foundation

// MARK: - Profile Link

nonisolated struct ProfileLink: Codable, Equatable, Identifiable {
    var id: UUID = .init()
    var title: String
    var url: String

    enum CodingKeys: String, CodingKey {
        case title, url
    }

    init(title: String = "", url: String = "") {
        self.title = title
        self.url = url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        url = try container.decode(String.self, forKey: .url)
    }
}

// MARK: - Profile Stats

nonisolated struct ProfileStats: Equatable {
    var followersCount: Int
    var followingCount: Int
    var projectsCount: Int

    init(followersCount: Int = 0, followingCount: Int = 0, projectsCount: Int = 0) {
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.projectsCount = projectsCount
    }
}

extension ProfileStats: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        followersCount = try container.decodeIfPresent(Int.self, forKey: .followersCount) ?? 0
        followingCount = try container.decodeIfPresent(Int.self, forKey: .followingCount) ?? 0
        projectsCount = try container.decodeIfPresent(Int.self, forKey: .projectsCount) ?? 0
    }
}

// MARK: - Profile

nonisolated struct Profile: Identifiable, Codable, Equatable {
    let id: String
    var username: String?
    var displayName: String?
    var avatarUrl: String?
    var bio: String?
    var links: [ProfileLink]
    let createdAt: Date
    var updatedAt: Date

    var stats: ProfileStats?
    var isFollowing: Bool?

    var name: String {
        displayName ?? username ?? "User"
    }

    var handle: String {
        username ?? displayName?.lowercased().replacingOccurrences(of: " ", with: "_") ?? "user"
    }

    var initial: String {
        String((displayName ?? username ?? "U").prefix(1)).uppercased()
    }

    var resolvedAvatarURL: URL? {
        guard let avatarUrl else { return nil }
        if avatarUrl.hasPrefix("http") { return URL(string: avatarUrl) }
        let ts = Int(updatedAt.timeIntervalSince1970)
        return URL(string: "\(Config.hostURL)\(avatarUrl)?v=\(ts)")
    }

    private enum CodingKeys: String, CodingKey {
        case id, username, displayName, avatarUrl, bio, links, createdAt, updatedAt, stats, isFollowing
    }

    init(
        id: String, username: String?, displayName: String?, avatarUrl: String?,
        bio: String?, links: [ProfileLink] = [], createdAt: Date = Date(), updatedAt: Date = Date(),
        stats: ProfileStats? = nil, isFollowing: Bool? = nil
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.bio = bio
        self.links = links
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.stats = stats
        self.isFollowing = isFollowing
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        links = try container.decodeIfPresent([ProfileLink].self, forKey: .links) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        stats = try container.decodeIfPresent(ProfileStats.self, forKey: .stats)
        isFollowing = try container.decodeIfPresent(Bool.self, forKey: .isFollowing)
    }
}

// MARK: - Sample Data

extension Profile {
    static let sample = Profile(
        id: "user_sample123",
        username: "creator",
        displayName: "Creative Dev",
        avatarUrl: nil,
        bio: "Building cool stuff with code",
        links: [
            ProfileLink(title: "GitHub", url: "https://github.com/creator"),
            ProfileLink(title: "Twitter", url: "https://twitter.com/creator"),
        ]
    )
}
