//
//  Comment.swift
//  Demoly
//

import Foundation

nonisolated struct Comment: Identifiable, Codable, Equatable {
    let id: String
    let projectId: String
    let userId: String
    var content: String
    var parentId: String?
    let createdAt: Date

    var user: CommentUser?
    var replyCount: Int?
}

nonisolated struct CommentUser: Codable, Equatable {
    let id: String
    let username: String?
    let displayName: String?
    let avatarUrl: String?

    var handle: String {
        username ?? displayName?.lowercased().replacingOccurrences(of: " ", with: "_") ?? "user"
    }

    var initial: String {
        String((displayName ?? username ?? "U").prefix(1)).uppercased()
    }

    var resolvedAvatarURL: URL? {
        guard let avatarUrl else { return nil }
        if avatarUrl.hasPrefix("http") { return URL(string: avatarUrl) }
        return URL(string: "\(Config.hostURL)\(avatarUrl)")
    }
}

// MARK: - Sample Data

extension Comment {
    static let sample = Comment(
        id: "comment-001",
        projectId: "project-001",
        userId: "user-001",
        content: "This is amazing!",
        parentId: nil,
        createdAt: Date(),
        user: CommentUser(id: "user-001", username: "creator", displayName: "Creative Dev", avatarUrl: nil),
        replyCount: 2
    )

    static let samples: [Comment] = [
        sample,
        Comment(
            id: "comment-002",
            projectId: "project-001",
            userId: "user-002",
            content: "Love the animation effect!",
            parentId: nil,
            createdAt: Date().addingTimeInterval(-3600),
            user: CommentUser(id: "user-002", username: "user2", displayName: "Designer", avatarUrl: nil),
            replyCount: 0
        ),
    ]
}
