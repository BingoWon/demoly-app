//
//  WebViewPool.swift
//  Demoly
//
//  LRU-bounded pool of pre-warmed WKWebViews for the fullscreen viewer.
//  Keeps the current page plus prefetched neighbours alive across SwiftUI
//  cell recycling so swipes never hit a cold load.
//
//  Capacity must be greater than 2 × prefetch radius + 1 so the visible
//  item and both neighbours never get evicted.
//

import WebKit

@MainActor
final class WebViewPool {
    static let shared = WebViewPool()

    private var entries: [String: Entry] = [:]
    private var order: [String] = []
    private let capacity = 5

    private struct Entry {
        let webView: WKWebView
        var version: Date
    }

    private init() {}

    /// Returns a WKWebView with the project's HTML loaded, reusing an existing
    /// instance when content is unchanged.
    func webView(for project: Project) -> WKWebView {
        if var entry = entries[project.id] {
            if entry.version != project.updatedAt {
                entry.webView.loadHTMLString(ProjectRenderer.render(project), baseURL: nil)
                entry.version = project.updatedAt
                entries[project.id] = entry
            }
            touch(project.id)
            return entry.webView
        }

        let webView = WebViewFactory.make()
        webView.loadHTMLString(ProjectRenderer.render(project), baseURL: nil)
        entries[project.id] = Entry(webView: webView, version: project.updatedAt)
        touch(project.id)
        evictIfNeeded()
        return webView
    }

    /// Pre-warm the WebViews for the current item plus its immediate neighbours.
    func prefetch(around index: Int, in projects: [Project]) {
        let lo = max(0, index - 1)
        let hi = min(projects.count - 1, index + 1)
        guard lo <= hi else { return }
        for i in lo ... hi { _ = webView(for: projects[i]) }
    }

    private func touch(_ id: String) {
        order.removeAll { $0 == id }
        order.append(id)
    }

    private func evictIfNeeded() {
        while order.count > capacity {
            let id = order.removeFirst()
            guard let entry = entries.removeValue(forKey: id) else { continue }
            entry.webView.stopLoading()
            entry.webView.removeFromSuperview()
        }
    }
}
