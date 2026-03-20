//
//  SearchViewModel.swift
//  Demoly
//

import Foundation

@MainActor
@Observable
final class SearchViewModel {
    private(set) var projects: [Project] = []
    private(set) var users: [Profile] = []
    private(set) var trendingTags: [String] = []

    private(set) var isSearching = false
    private(set) var isLoadingTrending = false

    var searchQuery = "" {
        didSet {
            if searchQuery != oldValue {
                searchTask?.cancel()
                if searchQuery.isEmpty {
                    projects = []
                    users = []
                } else {
                    scheduleSearch()
                }
            }
        }
    }

    private var searchTask: Task<Void, Never>?
    private let service = SearchService.shared

    // MARK: - Load Initial Data

    func loadTrending() async {
        guard trendingTags.isEmpty else { return }
        isLoadingTrending = true
        defer { isLoadingTrending = false }
        trendingTags = defaultTags
    }

    // MARK: - Search

    private func scheduleSearch() {
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await performSearch()
        }
    }

    private func performSearch() async {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }

        isSearching = true
        defer { isSearching = false }

        do {
            let searchQuery = query.hasPrefix("#") ? String(query.dropFirst()) : query
            let type = query.hasPrefix("#") ? "projects" : "all"
            let response = try await service.search(query: searchQuery, type: type)
            projects = response.projects
            users = response.users
        } catch {
            print("Search failed: \(error)")
        }
    }

    func searchTag(_ tag: String) {
        searchQuery = "#\(tag)"
    }

    private var defaultTags: [String] {
        ["animation", "3d", "particles", "gradient", "interactive", "generative"]
    }
}
