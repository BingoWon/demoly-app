//
//  ProjectWebView.swift
//  Demoly
//
//  Three rendering modes, one entry point.
//
//  • fullscreen — paging viewer; uses WebViewPool so swipes find a warm,
//                 pre-rendered WKWebView and SwiftUI cell recycling never
//                 discards the underlying instance.
//  • thumbnail  — grid cell; renders at the canonical design canvas
//                 (designWidth × designHeight) and scales geometrically
//                 to fit the cell, so the layout collapses cleanly on iPad
//                 widths where viewport injection is a no-op.
//  • editor     — live preview in the create flow; keyed by an external
//                 token so re-renders dedupe automatically.
//

import SwiftUI
import WebKit

private let designWidth: CGFloat = 390
private let designHeight: CGFloat = designWidth / GridMetrics.previewAspectRatio

// MARK: - Public API

struct ProjectWebView: View {
    private enum Mode {
        case fullscreen(Project)
        case thumbnail(Project, displayWidth: CGFloat)
        case editor(html: String, css: String, javascript: String, token: String)
    }

    private let mode: Mode

    init(project: Project) {
        mode = .fullscreen(project)
    }

    init(project: Project, displayWidth: CGFloat) {
        mode = .thumbnail(project, displayWidth: displayWidth)
    }

    init(html: String, css: String, javascript: String, token: String) {
        mode = .editor(html: html, css: css, javascript: javascript, token: token)
    }

    var body: some View {
        switch mode {
        case let .fullscreen(project):
            FullscreenWebView(project: project)
        case let .thumbnail(project, displayWidth):
            ThumbnailWebView(project: project, displayWidth: displayWidth)
        case let .editor(html, css, javascript, token):
            EditorPreviewWebView(html: html, css: css, javascript: javascript, token: token)
        }
    }
}

// MARK: - Fullscreen (pooled)

private struct FullscreenWebView: UIViewRepresentable {
    let project: Project

    func makeUIView(context _: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .black
        return container
    }

    func updateUIView(_ container: UIView, context _: Context) {
        let webView = WebViewPool.shared.webView(for: project)
        guard webView.superview !== container else { return }
        webView.removeFromSuperview()
        webView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: container.topAnchor),
            webView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
    }
}

// MARK: - Thumbnail (design-canvas + geometric scale)

private struct ThumbnailWebView: View {
    let project: Project
    let displayWidth: CGFloat

    var body: some View {
        let scale = displayWidth / designWidth
        let height = displayWidth / GridMetrics.previewAspectRatio
        Representable(project: project)
            .frame(width: designWidth, height: designHeight)
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: displayWidth, height: height, alignment: .topLeading)
    }

    private struct Representable: UIViewRepresentable {
        let project: Project

        func makeUIView(context _: Context) -> WKWebView {
            WebViewFactory.make(interactive: false)
        }

        func updateUIView(_ webView: WKWebView, context: Context) {
            context.coordinator.loadIfChanged(
                token: "\(project.id)#\(project.updatedAt.timeIntervalSince1970)",
                into: webView,
                html: ProjectRenderer.render(project)
            )
        }

        func makeCoordinator() -> TokenCoordinator {
            TokenCoordinator()
        }

        static func dismantleUIView(_ webView: WKWebView, coordinator _: TokenCoordinator) {
            webView.stopLoading()
        }
    }
}

// MARK: - Editor preview

private struct EditorPreviewWebView: UIViewRepresentable {
    let html: String
    let css: String
    let javascript: String
    let token: String

    func makeUIView(context _: Context) -> WKWebView {
        WebViewFactory.make(scrollable: true)
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.loadIfChanged(
            token: token,
            into: webView,
            html: ProjectRenderer.render(html: html, css: css, javascript: javascript)
        )
    }

    func makeCoordinator() -> TokenCoordinator {
        TokenCoordinator()
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator _: TokenCoordinator) {
        webView.stopLoading()
    }
}

// MARK: - Coordinator

private final class TokenCoordinator {
    private var token: String?

    func loadIfChanged(token newToken: String, into webView: WKWebView, html: @autoclosure () -> String) {
        guard token != newToken else { return }
        token = newToken
        webView.loadHTMLString(html(), baseURL: nil)
    }
}
