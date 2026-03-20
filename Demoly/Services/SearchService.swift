//
//  SearchService.swift
//  Demoly
//

import Foundation

actor SearchService {
    static let shared = SearchService()

    private let api = APIClient.shared

    private init() {}

    // MARK: - Search

    struct SearchResponse: Decodable {
        let projects: [Project]
        let users: [Profile]
    }

    func search(query: String, type: String = "all", limit: Int = 20) async throws -> SearchResponse {
        try await api.get(
            "/search",
            query: [
                "q": query,
                "type": type,
                "limit": "\(limit)",
            ]
        )
    }
}
