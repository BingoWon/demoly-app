//
//  ProjectRenderer.swift
//  Demoly
//

import Foundation

enum ProjectRenderer {
    /// Render from a Project model (Feed, Profile, Search, and all grid contexts).
    static func render(_ project: Project) -> String {
        render(
            title: project.title,
            html: project.htmlContent ?? "",
            css: project.cssContent ?? "",
            javascript: project.jsContent ?? ""
        )
    }

    /// Render from raw content (for Preview)
    static func render(title: String = "", html: String, css: String, javascript: String) -> String {
        if html.lowercased().contains("<html") {
            return applyDynamicPlatformPolicy(html)
        }

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
            <title>\(escapeHTML(title))</title>
            <style>* { margin: 0; padding: 0; box-sizing: border-box; } html, body { width: 100%; min-height: 100dvh; overflow: auto !important; background: #000; color: #fff; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }</style>
            <style>\(css)</style>
        </head>
        <body>
            \(html)
            <script type="module">\(javascript.replacingOccurrences(of: "</script", with: "<\\/script", options: .caseInsensitive))</script>
        </body>
        </html>
        """
    }

    private static func applyDynamicPlatformPolicy(_ rawHTML: String) -> String {
        var result = rawHTML
            .replacingOccurrences(of: "maximum-scale=1.0", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "user-scalable=no", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "maximum-scale=1", with: "", options: .caseInsensitive)

        let overrideStyle = "<style>html, body { overflow: auto !important; height: auto !important; min-height: 100vh; }</style>"

        if let range = result.range(of: "</head>", options: .caseInsensitive) {
            result.insert(contentsOf: overrideStyle, at: range.lowerBound)
        } else if let range = result.range(of: "<body>", options: .caseInsensitive) {
            result.insert(contentsOf: overrideStyle, at: range.upperBound)
        } else {
            result.append(overrideStyle)
        }

        return result
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
