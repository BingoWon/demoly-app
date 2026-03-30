//
//  ProjectWebView.swift
//  Demoly
//
//  iOS 26: Native SwiftUI WebView + WebPage
//  iOS 18: UIViewRepresentable + WKWebView
//
//  isInteractive: false → UIKit touches blocked, SwiftUI taps fall through
//  isLazy: true         → HTML cleared on disappear to free memory
//  changeToken          → triggers a reload when content changes without
//                         recreating the UIView (coordinator-based dedup)
//

import SwiftUI
import WebKit

// MARK: - Public Interface

struct ProjectWebView: View {
    private let renderedHTML: String
    /// Uniquely identifies the current content. When it changes, the WebView reloads.
    private let changeToken: String
    var isInteractive: Bool = true
    var isLazy: Bool = false

    /// Feed / grid usage: renders a Project model.
    init(project: Project, isInteractive: Bool = true, isLazy: Bool = false) {
        self.renderedHTML = ProjectRenderer.render(project)
        self.changeToken = project.id
        self.isInteractive = isInteractive
        self.isLazy = isLazy
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
                isLazy: isLazy
            )
        } else {
            LegacyProjectWebView(
                renderedHTML: renderedHTML,
                changeToken: changeToken,
                isInteractive: isInteractive
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
        webPage.load(html: renderedHTML)
    }
}

// MARK: - iOS 18: WKWebView via UIViewRepresentable

private struct LegacyProjectWebView: UIViewRepresentable {
    let renderedHTML: String
    let changeToken: String
    let isInteractive: Bool

    func makeUIView(context: Context) -> WKWebView {
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
        // Blocks UIKit-level touches in grid preview so taps reach SwiftUI
        webView.isUserInteractionEnabled = isInteractive
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.lastChangeToken != changeToken else { return }
        context.coordinator.lastChangeToken = changeToken
        webView.loadHTMLString(renderedHTML, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {
        var lastChangeToken: String?
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        // Clear JS engine when the cell is recycled / scrolled far away
        uiView.loadHTMLString("", baseURL: nil)
    }
}
