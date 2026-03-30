//
//  ProjectWebView.swift
//  Demoly
//
//  iOS 26: Native SwiftUI WebView + WebPage
//  iOS 18: UIViewRepresentable + WKWebView
//
//  isInteractive: false → UIKit touches blocked, SwiftUI taps fall through
//  isLazy: true        → HTML loaded on appear, cleared on disappear (grid mode)
//

import SwiftUI
import WebKit

struct ProjectWebView: View {
    let project: Project
    var isInteractive: Bool = true
    var isLazy: Bool = false

    var body: some View {
        if #available(iOS 26.0, *) {
            NativeProjectWebView(project: project, isInteractive: isInteractive, isLazy: isLazy)
        } else {
            LegacyProjectWebView(project: project, isInteractive: isInteractive, isLazy: isLazy)
        }
    }
}

// MARK: - iOS 26: Native SwiftUI WebView

@available(iOS 26.0, *)
private struct NativeProjectWebView: View {
    let project: Project
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
            .onChange(of: project.id) { _, _ in load() }
    }

    private func load() {
        webPage.load(html: ProjectRenderer.render(project))
    }
}

// MARK: - iOS 18: WKWebView via UIViewRepresentable

private struct LegacyProjectWebView: UIViewRepresentable {
    let project: Project
    let isInteractive: Bool
    let isLazy: Bool

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
        let html = ProjectRenderer.render(project)
        if context.coordinator.lastProjectId != project.id {
            context.coordinator.lastProjectId = project.id
            webView.loadHTMLString(html, baseURL: nil)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {
        var lastProjectId: String?
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        // Clear JS engine when the cell is recycled / scrolled far away
        uiView.loadHTMLString("", baseURL: nil)
    }
}

// MARK: - Grid preview wrapper

/// Wraps ProjectWebView with visibility-driven load/unload for masonry grid cells.
/// - Renders a black placeholder until the cell scrolls into view (lazy first load)
/// - Clears the WebView when the cell scrolls out (frees JS engine memory)
/// - Blocks all touches so taps fall through to .onTapGesture on the parent cell
struct GridProjectWebView: View {
    let project: Project

    @State private var isVisible = false

    var body: some View {
        Group {
            if isVisible {
                ProjectWebView(project: project, isInteractive: false, isLazy: true)
            } else {
                Color.black
            }
        }
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }
}
