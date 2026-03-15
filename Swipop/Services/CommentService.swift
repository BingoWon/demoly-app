//
//  CommentService.swift
//  Swipop
//

import Foundation

actor CommentService {
    static let shared = CommentService()

    private let api = APIClient.shared

    private init() {}

    // MARK: - Fetch

    struct CommentsResponse: Decodable {
        let items: [Comment]
    }

    func fetchComments(projectId: String, limit: Int = 20, offset: Int = 0) async throws -> [Comment] {
        let response: CommentsResponse = try await api.get(
            "/comments/\(projectId)",
            query: [
                "limit": "\(limit)",
                "offset": "\(offset)",
            ]
        )
        return response.items
    }

    // MARK: - Create

    struct CreateCommentPayload: Encodable {
        let content: String
        let parentId: String?
    }

    func createComment(projectId: String, content: String, parentId: String? = nil) async throws -> Comment {
        try await api.post("/comments/\(projectId)", body: CreateCommentPayload(content: content, parentId: parentId))
    }

    // MARK: - Delete

    func deleteComment(projectId: String, commentId: String) async throws {
        try await api.delete("/comments/\(projectId)/\(commentId)")
    }
}
