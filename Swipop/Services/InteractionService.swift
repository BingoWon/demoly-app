//
//  InteractionService.swift
//  Swipop
//

import Foundation

actor InteractionService {
    static let shared = InteractionService()

    private let api = APIClient.shared

    private init() {}

    // MARK: - Likes

    func like(projectId: String) async throws {
        try await api.post("/interactions/\(projectId)/like", body: EmptyPayload())
    }

    func unlike(projectId: String) async throws {
        try await api.delete("/interactions/\(projectId)/like")
    }

    // MARK: - Collections

    func collect(projectId: String) async throws {
        try await api.post("/interactions/\(projectId)/collect", body: EmptyPayload())
    }

    func uncollect(projectId: String) async throws {
        try await api.delete("/interactions/\(projectId)/collect")
    }
}
