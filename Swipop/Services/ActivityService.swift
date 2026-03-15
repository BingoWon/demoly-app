//
//  ActivityService.swift
//  Swipop
//

import Foundation

actor ActivityService {
    static let shared = ActivityService()

    private let api = APIClient.shared

    private init() {}

    // MARK: - Fetch

    struct ActivitiesResponse: Decodable {
        let items: [Activity]
    }

    func fetchActivities(limit: Int = 50, offset: Int = 0) async throws -> [Activity] {
        let response: ActivitiesResponse = try await api.get(
            "/activities",
            query: [
                "limit": "\(limit)",
                "offset": "\(offset)",
            ]
        )
        return response.items
    }

    // MARK: - Unread

    struct UnreadCountResponse: Decodable {
        let count: Int
    }

    func fetchUnreadCount() async throws -> Int {
        let response: UnreadCountResponse = try await api.get("/activities/unread-count")
        return response.count
    }

    // MARK: - Mark as Read

    func markAsRead(activityId: String) async throws {
        try await api.patch("/activities/\(activityId)/read", body: EmptyPayload())
    }

    func markAllAsRead() async throws {
        try await api.patch("/activities/read-all", body: EmptyPayload())
    }
}
