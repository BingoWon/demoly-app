//
//  UserService.swift
//  Demoly
//

import Foundation
import UIKit

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

    struct AvatarUploadResult: Decodable {
        let url: String
    }

    func uploadAvatar(image: UIImage) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw APIError.encodingFailed
        }
        let responseData = try await api.upload(
            "/upload/avatar",
            fileData: data,
            fileName: "avatar.jpg",
            mimeType: "image/jpeg"
        )
        let result = try JSONDecoder().decode(AvatarUploadResult.self, from: responseData)
        return result.url
    }

    // MARK: - Account

    func deleteAccount() async throws {
        try await api.delete("/me")
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
