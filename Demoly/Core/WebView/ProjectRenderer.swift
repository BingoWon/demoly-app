//
//  ProjectRenderer.swift
//  Demoly
//
//  Composes the final HTML document loaded into WKWebView.
//  Injects safe-area variables, viewport policy, and tap/selection defaults
//  so projects feel native inside a paging container.
//
//  Render results are memoised per (project.id + updatedAt) — composing the
//  HTML string is otherwise repeated on every SwiftUI re-evaluation.
//

import Foundation

enum ProjectRenderer {
    private static let cache: NSCache<NSString, NSString> = {
        let c = NSCache<NSString, NSString>()
        c.totalCostLimit = 8 * 1024 * 1024
        return c
    }()

    /// Render from a Project. Memoised by id + updatedAt.
    static func render(_ project: Project) -> String {
        let key = "\(project.id)#\(project.updatedAt.timeIntervalSince1970)" as NSString
        if let cached = cache.object(forKey: key) { return cached as String }
        let html = render(
            title: project.title,
            html: project.htmlContent ?? "",
            css: project.cssContent ?? "",
            javascript: project.jsContent ?? ""
        )
        cache.setObject(html as NSString, forKey: key, cost: html.utf8.count)
        return html
    }

    /// Render from raw fragments (editor preview / sample content).
    static func render(title: String = "", html: String, css: String, javascript: String) -> String {
        if html.lowercased().contains("<html") {
            return injectIntoUserDocument(html)
        }
        return wrapBareFragment(title: title, html: html, css: css, javascript: javascript)
    }

    // MARK: - Wrappers

    private static func wrapBareFragment(title: String, html: String, css: String, javascript: String) -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        \(viewportMeta)
        <title>\(escapeHTML(title))</title>
        \(baseStyle)
        <style>\(css)</style>
        </head>
        <body>
        \(html)
        <script type="module">\(sanitizeScript(javascript))</script>
        </body>
        </html>
        """
    }

    /// Injects our viewport + base style at the *top* of the document head so
    /// any user-supplied CSS that follows wins on conflict.
    private static func injectIntoUserDocument(_ raw: String) -> String {
        var result = raw

        let viewportPattern = #"<meta\s+[^>]*name=["']viewport["'][^>]*>"#
        if let range = result.range(of: viewportPattern, options: [.regularExpression, .caseInsensitive]) {
            result.replaceSubrange(range, with: viewportMeta + baseStyle)
        } else if let range = result.range(of: "<head>", options: .caseInsensitive) {
            result.insert(contentsOf: viewportMeta + baseStyle, at: range.upperBound)
        } else if let range = result.range(of: "<body", options: .caseInsensitive) {
            result.insert(contentsOf: viewportMeta + baseStyle, at: range.lowerBound)
        } else {
            result = viewportMeta + baseStyle + result
        }

        return result
    }

    // MARK: - Shared building blocks

    private static let viewportMeta =
        #"<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover, user-scalable=no">"#

    private static let baseStyle = """
    <style>
    :root {
        --safe-top: env(safe-area-inset-top);
        --safe-right: env(safe-area-inset-right);
        --safe-bottom: env(safe-area-inset-bottom);
        --safe-left: env(safe-area-inset-left);
    }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body {
        width: 100%;
        min-height: 100dvh;
        /* Platform contract: works that exceed one viewport must remain reachable.
           WebKit handles this scroll internally and yields the gesture to the
           outer SwiftUI paging container at the edges, so the two compose without
           UIKit-level coordination. */
        overflow: auto !important;
        background: #000;
        color: #fff;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        -webkit-tap-highlight-color: transparent;
        -webkit-touch-callout: none;
    }
    body { -webkit-user-select: none; user-select: none; }
    input, textarea, select, [contenteditable] {
        -webkit-user-select: text;
        user-select: text;
        -webkit-touch-callout: default;
    }
    </style>
    """

    // MARK: - Helpers

    private static func sanitizeScript(_ js: String) -> String {
        js.replacingOccurrences(of: "</script", with: "<\\/script", options: .caseInsensitive)
    }

    private static func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
