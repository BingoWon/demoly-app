//
//  ProjectWebView.swift
//  Demoly
//
//  Grid preview rendering strategy (device-agnostic):
//
//  WKWebView always renders at DESIGN_WIDTH (390 pt) — the iPhone design canvas.
//  When `displayWidth` is provided (grid/thumbnail), SwiftUI's `.scaleEffect`
//  uniformly scales the rendered output from the top-leading corner so the
//  displayed footprint is exactly `displayWidth` wide.
//
//  WHY NOT viewport injection?
//  `viewport width=N` only shrinks content when N > frame width; on iPad the
//  grid cells can be wider than 390 pt, so the browser renders at full size
//  and the content overflows. SwiftUI `.scaleEffect` works on all device sizes
//  because the scale factor is derived purely from layout geometry.
//
//  displayWidth == nil  → full-screen interactive viewer (scale = 1)
//  displayWidth != nil  → grid thumbnail (scale = displayWidth / DESIGN_WIDTH)
//
//  isInteractive: false → UIKit touches blocked, SwiftUI taps pass through
//  isLazy: true         → HTML cleared on disappear to free memory
//  changeToken          → coordinator-based dedup prevents redundant reloads
//

import SwiftUI
import WebKit

// MARK: - Constants

/// The canonical iPhone portrait design width for all project HTML rendering.
let DESIGN_WIDTH: CGFloat = 390

// MARK: - Public Interface

struct ProjectWebView: View {
    private let renderedHTML: String
    private let changeToken: String
    var isInteractive: Bool = true
    var isLazy: Bool = false
    /// Provide to render at DESIGN_WIDTH and scale down to this width.
    var displayWidth: CGFloat?

    // MARK: Initialisers

    /// Grid / thumbnail usage — scales content to fit `displayWidth`.
    init(
        project: Project,
        isInteractive: Bool = true,
        isLazy: Bool = false,
        displayWidth: CGFloat? = nil
    ) {
        self.renderedHTML = ProjectRenderer.render(project)
        self.changeToken = project.id
        self.isInteractive = isInteractive
        self.isLazy = isLazy
        self.displayWidth = displayWidth
    }

    /// Editor preview — renders at full DESIGN_WIDTH, no scaling.
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
                displayWidth: displayWidth
            )
        } else {
            LegacyProjectWebView(
                renderedHTML: renderedHTML,
                changeToken: changeToken,
                isInteractive: isInteractive,
                displayWidth: displayWidth
            )
        }
    }
}

// MARK: - Scale helper

/// Uniform scale factor to display DESIGN_WIDTH content in `displayWidth` pt.
private func gridScale(for displayWidth: CGFloat?) -> CGFloat {
    guard let w = displayWidth, w > 0 else { return 1 }
    return w / DESIGN_WIDTH
}

// MARK: - iOS 26: Native SwiftUI WebView

@available(iOS 26.0, *)
private struct NativeProjectWebView: View {
    let renderedHTML: String
    let changeToken: String
    let isInteractive: Bool
    let isLazy: Bool
    let displayWidth: CGFloat?

    @State private var webPage = WebPage()

    var body: some View {
        let s = gridScale(for: displayWidth)
        WebView(webPage)
            .webViewContentBackground(.hidden)
            .webViewBackForwardNavigationGestures(.disabled)
            .allowsHitTesting(isInteractive)
            // Always render at the design canvas width…
            .frame(width: DESIGN_WIDTH)
            // …then scale uniformly from the top-leading origin…
            .scaleEffect(s, anchor: .topLeading)
            // …and collapse the layout footprint to the actual display size.
            .frame(width: displayWidth ?? DESIGN_WIDTH, alignment: .topLeading)
            .onAppear { webPage.load(html: renderedHTML) }
            .onDisappear {
                if isLazy { webPage.load(URLRequest(url: URL(string: "about:blank")!)) }
            }
            .onChange(of: changeToken) { _, _ in webPage.load(html: renderedHTML) }
    }
}

// MARK: - iOS 18: WKWebView via UIViewRepresentable

/// Raw WKWebView wrapper — no transforms applied inside UIViewRepresentable.
/// Scaling is done purely on the SwiftUI layer in `LegacyProjectWebView` below.
private struct RawWKWebView: UIViewRepresentable {
    let renderedHTML: String
    let changeToken: String
    let isInteractive: Bool

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
        webView.loadHTMLString(renderedHTML, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {
        var lastChangeToken: String?
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator _: Coordinator) {
        uiView.loadHTMLString("", baseURL: nil)
    }
}

/// SwiftUI wrapper: renders at DESIGN_WIDTH, scales to `displayWidth` on the
/// SwiftUI layer only — zero UIKit transform involvement.
private struct LegacyProjectWebView: View {
    let renderedHTML: String
    let changeToken: String
    let isInteractive: Bool
    let displayWidth: CGFloat?

    var body: some View {
        let s = gridScale(for: displayWidth)
        RawWKWebView(
            renderedHTML: renderedHTML,
            changeToken: changeToken,
            isInteractive: isInteractive
        )
        // Always render at the design canvas width…
        .frame(width: DESIGN_WIDTH)
        // …then scale uniformly from the top-leading origin…
        .scaleEffect(s, anchor: .topLeading)
        // …and collapse the layout footprint to the actual display size.
        .frame(width: displayWidth ?? DESIGN_WIDTH, alignment: .topLeading)
    }
}
