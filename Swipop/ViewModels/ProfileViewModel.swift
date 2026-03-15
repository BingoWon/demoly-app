//
//  ProfileViewModel.swift
//  Swipop
//

import ClerkKit
import Foundation

// MARK: - Current User Profile (Singleton)

@MainActor
@Observable
final class CurrentUserProfile {
    static let shared = CurrentUserProfile()

    private(set) var profile: Profile?
    private(set) var projects: [Project] = []

    private(set) var isLoading = false
    private(set) var isRefreshing = false
    private(set) var hasLoaded = false

    var followerCount: Int { profile?.stats?.followersCount ?? 0 }
    var followingCount: Int { profile?.stats?.followingCount ?? 0 }
    var projectCount: Int { profile?.stats?.projectsCount ?? 0 }

    private let userService = UserService.shared
    private let projectService = ProjectService.shared

    private init() {}

    func preload() async {
        guard Clerk.shared.user != nil else { return }
        isLoading = true
        defer { isLoading = false }
        await fetchData()
        hasLoaded = true
    }

    func refresh() async {
        guard Clerk.shared.user != nil else { return }
        guard hasLoaded else {
            await preload()
            return
        }
        isRefreshing = true
        defer { isRefreshing = false }
        await fetchData()
    }

    func reset() {
        profile = nil
        projects = []
        hasLoaded = false
    }

    private func fetchData() async {
        do {
            let me = try await userService.fetchMe()
            profile = me

            if let userId = Clerk.shared.user?.id {
                projects = try await projectService.fetchUserProjects(userId: userId)
            }
        } catch {
            print("Failed to load profile: \(error)")
        }
    }
}

// MARK: - Other User Profile

@MainActor
@Observable
final class OtherUserProfileViewModel {
    let username: String

    private(set) var profile: Profile?
    private(set) var projects: [Project] = []
    private(set) var isFollowing = false
    private(set) var isLoading = true

    var followerCount: Int { profile?.stats?.followersCount ?? 0 }
    var followingCount: Int { profile?.stats?.followingCount ?? 0 }
    var projectCount: Int { profile?.stats?.projectsCount ?? 0 }

    var isSelf: Bool { Clerk.shared.user?.id == profile?.id }

    private let userService = UserService.shared
    private let projectService = ProjectService.shared

    init(username: String) {
        self.username = username
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await userService.fetchUser(username: username)
            profile = user
            isFollowing = user.isFollowing ?? false
            projects = try await projectService.fetchUserProjects(userId: user.id)
        } catch {
            print("Failed to load profile: \(error)")
        }
    }

    func toggleFollow() async {
        guard !isSelf, let profileId = profile?.id else { return }
        let wasFollowing = isFollowing
        isFollowing.toggle()

        do {
            if isFollowing {
                try await userService.follow(userId: profileId)
            } else {
                try await userService.unfollow(userId: profileId)
            }
        } catch {
            isFollowing = wasFollowing
            print("Failed to toggle follow: \(error)")
        }
    }
}
