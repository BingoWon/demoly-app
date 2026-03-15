//
//  ProjectWebView.swift
//  Swipop
//
//  iOS 26: Native SwiftUI WebView + WebPage
//  iOS 18: UIViewRepresentable + WKWebView
//

import SwiftUI
import WebKit

struct ProjectWebView: View {
    let project: Project

    var body: some View {
        if #available(iOS 26.0, *) {
            NativeProjectWebView(project: project)
        } else {
            LegacyProjectWebView(project: project)
        }
    }
}

// MARK: - iOS 26: Native SwiftUI WebView

@available(iOS 26.0, *)
private struct NativeProjectWebView: View {
    let project: Project
    @State private var webPage = WebPage()

    var body: some View {
        WebView(webPage)
            .webViewContentBackground(.hidden)
            .webViewBackForwardNavigationGestures(.disabled)
            .task(id: project.id) {
                let html = ProjectRenderer.render(project)
                webPage.load(html: html)
            }
    }
}

// MARK: - iOS 18: WKWebView via UIViewRepresentable

private struct LegacyProjectWebView: UIViewRepresentable {
    let project: Project

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
}
