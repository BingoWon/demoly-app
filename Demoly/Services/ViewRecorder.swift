//
//  ViewRecorder.swift
//  Demoly
//
//  Debounced view-count recorder. A project counts as viewed only after the
//  user dwells on it for one second; each project is counted at most once
//  per session.
//

import Foundation

@MainActor
final class ViewRecorder {
    static let shared = ViewRecorder()

    private var recorded: Set<String> = []
    private var pending: Task<Void, Never>?

    private init() {}

    func schedule(projectId: String) {
        pending?.cancel()
        guard !recorded.contains(projectId) else { return }

        pending = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            recorded.insert(projectId)
            try? await ProjectService.shared.recordView(id: projectId)
        }
    }

    func reset() {
        pending?.cancel()
        recorded.removeAll()
    }
}
