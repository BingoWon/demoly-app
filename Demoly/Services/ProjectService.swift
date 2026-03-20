//
//  ProjectService.swift
//  Demoly
//

import Foundation

actor ProjectService {
    static let shared = ProjectService()

    private let api = APIClient.shared

    private init() {}

    // MARK: - Feed

    struct FeedResponse: Decodable {
        let items: [Project]
        let total: Int
        let hasMore: Bool
    }

    func fetchFeed(limit: Int = 20, offset: Int = 0) async throws -> FeedResponse {
        try await api.get(
            "/feed",
            query: [
                "limit": "\(limit)",
                "offset": "\(offset)",
            ]
        )
    }

    // MARK: - Single Project

    func fetchProject(id: String) async throws -> Project {
        try await api.get("/projects/\(id)")
    }

    // MARK: - User Projects

    struct ProjectListResponse: Decodable {
        let items: [Project]
    }

    func fetchUserProjects(userId: String) async throws -> [Project] {
        let response: ProjectListResponse = try await api.get("/users/\(userId)/projects")
        return response.items
    }

    // MARK: - Create / Update / Delete

    struct CreateProjectPayload: Encodable {
        let title: String
        let description: String?
        let tags: [String]
        let htmlContent: String?
        let cssContent: String?
        let jsContent: String?
        let chatMessages: [[String: AnyCodable]]?
        let isPublished: Bool
        let thumbnailUrl: String?
        let thumbnailAspectRatio: Double?
    }

    func createProject(payload: CreateProjectPayload) async throws -> Project {
        try await api.post("/projects", body: payload)
    }

    func updateProject(id: String, payload: CreateProjectPayload) async throws -> Project {
        try await api.patch("/projects/\(id)", body: payload)
    }

    func deleteProject(id: String) async throws {
        try await api.delete("/projects/\(id)")
    }

    func recordView(id: String) async throws {
        try await api.post("/projects/\(id)/view", body: EmptyPayload())
    }

    // MARK: - Errors

    enum ProjectError: LocalizedError {
        case notAuthenticated

        var errorDescription: String? {
            switch self {
            case .notAuthenticated: "Please sign in to save projects"
            }
        }
    }
}
