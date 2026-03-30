//
//  ProjectWebView.swift
//  Demoly
//
//  iOS 26: Native SwiftUI WebView + WebPage
//  iOS 18: UIViewRepresentable + WKWebView
//
//  isInteractive: false → UIKit touches blocked, SwiftUI taps fall through
//  isLazy: true         → HTML cleared on disappear to free memory
//  useGridViewport      → injects viewport width=390 so WKWebView renders at
//                         design width and auto-scales to fit the cell frame
//  changeToken          → triggers a reload when content changes without
//                         recreating the UIView (coordinator-based dedup)
//

import SwiftUI
import WebKit

// MARK: - Constants

/// The canonical iPhone design width. When `useGridViewport` is true, WKWebView
/// renders the page at this width and automatically scales to its actual frame.
private let DESIGN_WIDTH: CGFloat = 390

// MARK: - Public Interface

struct ProjectWebView: View {
    private let renderedHTML: String
    private let changeToken: String
    var isInteractive: Bool = true
    var isLazy: Bool = false
    /// When true, forces viewport to DESIGN_WIDTH so the content scales to fit.
    var useGridViewport: Bool = false

    /// Feed / grid usage: renders a Project model.
    init(project: Project, isInteractive: Bool = true, isLazy: Bool = false, useGridViewport: Bool = false) {
        self.renderedHTML = ProjectRenderer.render(project)
        self.changeToken = project.id
        self.isInteractive = isInteractive
        self.isLazy = isLazy
        self.useGridViewport = useGridViewport
    }

    /// Editor preview usage: renders raw HTML / CSS / JS.
    init(html: String, css: String, javascript: String, isInteractive: Bool = true) {
        let r = ProjectRenderer.render(html: html, css: css, javascript: javascript)
        self.renderedHTML = r
        self.changeToken = String(r.hashValue)
        self.isInteractive = isInteractive
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            NativeProjectWebView(
                renderedHTML: renderedHTML,
                changeToken: changeToken,
                isInteractive: isInteractive,
                isLazy: isLazy,
                useGridViewport: useGridViewport
            )
        } else {
            LegacyProjectWebView(
                renderedHTML: renderedHTML,
                changeToken: changeToken,
                isInteractive: isInteractive,
                useGridViewport: useGridViewport
            )
        }
    }
}


// MARK: - iOS 26: Native SwiftUI WebView

@available(iOS 26.0, *)
private struct NativeProjectWebView: View {
    let renderedHTML: String
    let changeToken: String
    let isInteractive: Bool
    let isLazy: Bool
    let useGridViewport: Bool

    @State private var webPage = WebPage()

    var body: some View {
        WebView(webPage)
            .webViewContentBackground(.hidden)
            .webViewBackForwardNavigationGestures(.disabled)
            .allowsHitTesting(isInteractive)
            .onAppear { load() }
            .onDisappear { if isLazy { webPage.load(URLRequest(url: URL(string: "about:blank")!)) } }
            .onChange(of: changeToken) { _, _ in load() }
    }

    private func load() {
        let html = useGridViewport ? injectFixedViewport(renderedHTML) : renderedHTML
        webPage.load(html: html)
    }
}

// MARK: - iOS 18: WKWebView via UIViewRepresentable

private struct LegacyProjectWebView: UIViewRepresentable {
    let renderedHTML: String
    let changeToken: String
    let isInteractive: Bool
    let useGridViewport: Bool

    func makeUIView(context _: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.alwaysBounceHorizontal = false
        webView.scrollView.isScrollEnabled = false
        webView.isUserInteractionEnabled = isInteractive
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.lastChangeToken != changeToken else { return }
        context.coordinator.lastChangeToken = changeToken
        let html = useGridViewport ? injectFixedViewport(renderedHTML) : renderedHTML
        webView.loadHTMLString(html, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var lastChangeToken: String?
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator _: Coordinator) {
        uiView.loadHTMLString("", baseURL: nil)
    }
}

// MARK: - Viewport Injection

/// Replaces / injects `<meta name="viewport">` with a fixed design width
/// so WKWebView renders at DESIGN_WIDTH and auto-scales to the cell frame.
private func injectFixedViewport(_ html: String) -> String {
    let fixedTag = "<meta name=\"viewport\" content=\"width=\(Int(DESIGN_WIDTH))\">"
    // Try to replace existing viewport tag
    if let range = html.range(of: "<meta[^>]*name=[\"']viewport[\"'][^>]*>", options: .regularExpression, range: html.startIndex..<html.endIndex) {
        var result = html
        result.replaceSubrange(range, with: fixedTag)
        return result
    }
    // Inject before </head> if no viewport exists
    if let range = html.range(of: "</head>", options: .caseInsensitive) {
        var result = html
        result.insert(contentsOf: fixedTag, at: range.lowerBound)
        return result
    }
    return html
}
