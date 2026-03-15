//
//  FeedViewModel.swift
//  Swipop
//

import ClerkKit
import Foundation

@MainActor
@Observable
final class FeedViewModel {
    static let shared = FeedViewModel()

    private(set) var projects: [Project] = []
    private(set) var currentIndex = 0
    private(set) var isLoading = false
    private(set) var error: String?

    private var hasMorePages = true
    private var needsRefresh = false
    private var hasInitialLoad = false
    private var currentTask: Task<Void, Never>?
    private let pageSize = 20

    var currentProject: Project? {
        guard currentIndex >= 0, currentIndex < projects.count else { return nil }
        return projects[currentIndex]
    }

    var isEmpty: Bool { !isLoading && projects.isEmpty }

    private init() {}

    // MARK: - Navigation

    func setCurrentProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            currentIndex = index
        }
    }

    func goToNext() {
        guard currentIndex < projects.count - 1 else { return }
        currentIndex += 1
        if currentIndex >= projects.count - 3 { loadMore() }
    }

    func goToPrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    // MARK: - Loading

    func loadInitial() {
        guard !hasInitialLoad else { return }
        hasInitialLoad = true
        performLoad()
    }

    func refresh() async {
        currentTask?.cancel()
        await doLoadFeed()
    }

    func markNeedsRefresh() { needsRefresh = true }

    func refreshIfNeeded() {
        if needsRefresh {
            needsRefresh = false
            performLoad()
        }
    }

    private func performLoad() {
        currentTask?.cancel()
        currentTask = Task.detached { [weak self] in
            await self?.doLoadFeed()
        }
    }

    private func doLoadFeed() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            let response = try await ProjectService.shared.fetchFeed(limit: pageSize, offset: 0)
            guard !Task.isCancelled else { return }
            projects = response.items
            hasMorePages = response.hasMore
            currentIndex = 0
            InteractionStore.shared.updateFromProjects(projects)
        } catch {
            guard !Task.isCancelled else { return }
            self.error = error.localizedDescription
            print("Failed to load feed: \(error)")
        }

        isLoading = false
    }

    func loadMore() {
        guard !isLoading, hasMorePages else { return }
        Task.detached { [weak self] in
            await self?.doLoadMore()
        }
    }

    private func doLoadMore() async {
        guard !isLoading, hasMorePages else { return }
        isLoading = true

        do {
            let currentCount = projects.count
            let response = try await ProjectService.shared.fetchFeed(limit: pageSize, offset: currentCount)
            guard !Task.isCancelled else { return }
            if response.items.isEmpty {
                hasMorePages = false
            } else {
                projects.append(contentsOf: response.items)
                InteractionStore.shared.updateFromProjects(response.items)
            }
        } catch {
            print("Failed to load more: \(error)")
        }

        isLoading = false
    }
}
