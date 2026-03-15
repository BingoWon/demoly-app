//
//  UserService.swift
//  Swipop
//

import Foundation

actor UserService {
    static let shared = UserService()

    private let api = APIClient.shared

    private init() {}

    // MARK: - Profile

    func fetchMe() async throws -> Profile {
        try await api.get("/me")
    }

    func fetchUser(username: String) async throws -> Profile {
        try await api.get("/users/\(username)")
    }

    func updateProfile(_ payload: ProfileUpdatePayload) async throws -> Profile {
        try await api.patch("/me", body: payload)
    }

    // MARK: - Follow

    func follow(userId: String) async throws {
        try await api.post("/follows/\(userId)/follow", body: EmptyPayload())
    }

    func unfollow(userId: String) async throws {
        try await api.delete("/follows/\(userId)/follow")
    }
}

// MARK: - Payloads

struct ProfileUpdatePayload: Encodable {
    var username: String?
    var displayName: String?
    var bio: String?
    var links: [ProfileLink]?
}
