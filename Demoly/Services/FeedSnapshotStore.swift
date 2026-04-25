//
//  FeedSnapshotStore.swift
//  Demoly
//
//  Persists the most recent feed page to disk so cold launches can show
//  content immediately while the network refresh runs in the background.
//

import Foundation

enum FeedSnapshotStore {
    private static let limit = 20

    private static let url: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("feed-snapshot.json")
    }()

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    static func load() -> [Project]? {
        guard let data = try? Data(contentsOf: url),
              let projects = try? decoder.decode([Project].self, from: data),
              !projects.isEmpty
        else { return nil }
        return projects
    }

    static func save(_ projects: [Project]) {
        let snapshot = Array(projects.prefix(limit))
        let url = url
        let encoder = encoder
        Task.detached(priority: .background) {
            guard let data = try? encoder.encode(snapshot) else { return }
            try? data.write(to: url, options: .atomic)
        }
    }

    static func clear() {
        try? FileManager.default.removeItem(at: url)
    }
}
