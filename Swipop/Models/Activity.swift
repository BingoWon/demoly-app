//
//  Activity.swift
//  Swipop
//

import SwiftUI

struct Activity: Identifiable, Codable, Hashable {
    let id: String
    let userId: String
    let actorId: String
    let type: ActivityType
    let projectId: String?
    let commentId: String?
    var isRead: Bool
    let createdAt: Date

    let actor: Profile?
    let project: Project?

    var timeAgo: String {
        createdAt.timeAgo
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Activity, rhs: Activity) -> Bool {
        lhs.id == rhs.id
    }
}

enum ActivityType: String, Codable {
    case like, comment, follow, collect

    var icon: String {
        switch self {
        case .like: "heart.fill"
        case .comment: "bubble.right.fill"
        case .follow: "person.badge.plus"
        case .collect: "bookmark.fill"
        }
    }

    var color: Color {
        switch self {
        case .like: .red
        case .comment: .blue
        case .follow: .purple
        case .collect: .yellow
        }
    }

    func message(actorName: String, projectTitle: String?) -> AttributedString {
        var result: AttributedString

        switch self {
        case .like:
            result = AttributedString("\(actorName) liked your project")
            if let title = projectTitle, !title.isEmpty {
                result += AttributedString(" \"\(title)\"")
            }
        case .comment:
            result = AttributedString("\(actorName) commented on")
            if let title = projectTitle, !title.isEmpty {
                result += AttributedString(" \"\(title)\"")
            } else {
                result += AttributedString(" your project")
            }
        case .follow:
            result = AttributedString("\(actorName) started following you")
        case .collect:
            result = AttributedString("\(actorName) saved your project")
            if let title = projectTitle, !title.isEmpty {
                result += AttributedString(" \"\(title)\"")
            }
        }

        if let range = result.range(of: actorName) {
            result[range].font = .system(size: 14, weight: .semibold)
        }

        return result
    }
}
