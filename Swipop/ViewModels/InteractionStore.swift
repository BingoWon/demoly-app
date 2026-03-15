//
//  InteractionStore.swift
//  Swipop
//
//  Centralized state for project interactions (like, collect)
//

import ClerkKit
import Foundation

@MainActor
@Observable
final class InteractionStore {
    static let shared = InteractionStore()

    // MARK: - State

    private var states: [String: InteractionState] = [:]

    // MARK: - Services

    private let service = InteractionService.shared

    // MARK: - Persistence Keys

    private let likedKey = "InteractionStore.likedProjects"
    private let collectedKey = "InteractionStore.collectedProjects"

    private init() {
        loadFromDisk()
    }

    // MARK: - Read State

    func isLiked(_ projectId: String) -> Bool {
        states[projectId]?.isLiked ?? false
    }

    func isCollected(_ projectId: String) -> Bool {
        states[projectId]?.isCollected ?? false
    }

    func likeCount(_ projectId: String) -> Int {
        states[projectId]?.likeCount ?? 0
    }

    func collectCount(_ projectId: String) -> Int {
        states[projectId]?.collectCount ?? 0
    }

    // MARK: - Initialize from Projects

    func updateFromProjects(_ projects: [Project]) {
        for project in projects {
            var state = states[project.id] ?? InteractionState()
            if let liked = project.isLikedByCurrentUser { state.isLiked = liked }
            if let collected = project.isCollectedByCurrentUser { state.isCollected = collected }
            state.likeCount = project.likeCount
            state.collectCount = project.collectCount
            states[project.id] = state
        }
        saveToDisk()
    }

    // MARK: - Toggle Like

    func toggleLike(projectId: String) async {
        guard Clerk.shared.user != nil else { return }

        var state = states[projectId] ?? InteractionState()
        let wasLiked = state.isLiked

        state.isLiked.toggle()
        state.likeCount += state.isLiked ? 1 : -1
        states[projectId] = state
        saveToDisk()

        do {
            if state.isLiked {
                try await service.like(projectId: projectId)
            } else {
                try await service.unlike(projectId: projectId)
            }
        } catch {
            state.isLiked = wasLiked
            state.likeCount += wasLiked ? 1 : -1
            states[projectId] = state
            saveToDisk()
            print("Failed to toggle like: \(error)")
        }
    }

    // MARK: - Toggle Collect

    func toggleCollect(projectId: String) async {
        guard Clerk.shared.user != nil else { return }

        var state = states[projectId] ?? InteractionState()
        let wasCollected = state.isCollected

        state.isCollected.toggle()
        state.collectCount += state.isCollected ? 1 : -1
        states[projectId] = state
        saveToDisk()

        do {
            if state.isCollected {
                try await service.collect(projectId: projectId)
            } else {
                try await service.uncollect(projectId: projectId)
            }
        } catch {
            state.isCollected = wasCollected
            state.collectCount += wasCollected ? 1 : -1
            states[projectId] = state
            saveToDisk()
            print("Failed to toggle collect: \(error)")
        }
    }

    // MARK: - Reset (on logout)

    func reset() {
        states.removeAll()
        UserDefaults.standard.removeObject(forKey: likedKey)
        UserDefaults.standard.removeObject(forKey: collectedKey)
    }

    // MARK: - Persistence

    private func loadFromDisk() {
        if let likedIds = UserDefaults.standard.stringArray(forKey: likedKey) {
            for id in likedIds {
                var state = states[id] ?? InteractionState()
                state.isLiked = true
                states[id] = state
            }
        }
        if let collectedIds = UserDefaults.standard.stringArray(forKey: collectedKey) {
            for id in collectedIds {
                var state = states[id] ?? InteractionState()
                state.isCollected = true
                states[id] = state
            }
        }
    }

    private func saveToDisk() {
        let likedIds = states.filter(\.value.isLiked).map(\.key)
        let collectedIds = states.filter(\.value.isCollected).map(\.key)
        UserDefaults.standard.set(likedIds, forKey: likedKey)
        UserDefaults.standard.set(collectedIds, forKey: collectedKey)
    }
}

private struct InteractionState {
    var isLiked = false
    var isCollected = false
    var likeCount = 0
    var collectCount = 0
}
