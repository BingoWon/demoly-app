//
//  ProjectWebView.swift
//  Demoly
//
//  Grid thumbnail rendering strategy (device-agnostic):
//
//  WKWebView always renders at the design canvas (DESIGN_WIDTH × DESIGN_HEIGHT).
//  When `displayWidth` is provided, SwiftUI `.scaleEffect` scales the canvas
//  uniformly and the outer `.frame` collapses BOTH width and height to the
//  actual display footprint — ensuring no blank space below the content.
//
//  WHY NOT viewport injection?
//  `viewport width=N` only shrinks content when N > WKWebView frame width.
//  On iPad, grid cells can be wider than 390pt so viewport injection has no
//  effect. SwiftUI `.scaleEffect` works on all sizes because it is purely
//  geometric and device-agnostic.
//
//  WHY explicit DESIGN_HEIGHT?
//  `.scaleEffect` is visual-only — it does not change the layout size. If
//  only width is forced, the layout height remains the full unscaled value,
//  leaving blank space below scaled content. Fixing both dimensions in the
//  final `.frame` collapses layout to exactly the visible footprint.
//
//  displayWidth == nil  → full-screen viewer / editor preview (no constraints)
//  displayWidth != nil  → grid thumbnail (both width and height managed)
//
//  isInteractive: false → UIKit touches blocked, SwiftUI taps pass through
//  isLazy: true         → HTML cleared on disappear to free memory
//  changeToken          → coordinator-based dedup prevents redundant reloads
//

import SwiftUI
import WebKit

// MARK: - Design Canvas Constants

/// Canonical iPhone portrait design width for all project HTML rendering.
private let DESIGN_WIDTH: CGFloat = 390

/// Canonical canvas height derived from the shared preview aspect ratio (9:19).
private let DESIGN_HEIGHT: CGFloat = DESIGN_WIDTH / GridMetrics.previewAspectRatio

// MARK: - Public Interface

struct ProjectWebView: View {
    private let renderedHTML: String
    private let changeToken: String
    var isInteractive: Bool = true
    var isLazy: Bool = false
    /// When set, content is rendered at the design canvas and scaled to this width.
    var displayWidth: CGFloat?

    // MARK: Initialisers

    /// Grid / thumbnail — scales a Project's rendered HTML to fit `displayWidth`.
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

    /// Editor preview — renders raw HTML/CSS/JS at full size, no scaling.
    init(html: String, css: String, javascript: String, changeToken: String = "", isInteractive: Bool = true) {
        let r = ProjectRenderer.render(html: html, css: css, javascript: javascript)
        self.renderedHTML = r
        self.changeToken = changeToken.isEmpty ? String(r.hashValue) : changeToken
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

// MARK: - Scale helpers

private extension CGFloat {
    /// Uniform scale factor: DESIGN_WIDTH → self (for grid thumbnails).
    var gridScale: CGFloat { self / DESIGN_WIDTH }
    /// Cell height matching the preview aspect ratio.
    var previewHeight: CGFloat { self / GridMetrics.previewAspectRatio }
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
        let isGrid = displayWidth != nil
        let s = displayWidth?.gridScale ?? 1
        let dh = displayWidth?.previewHeight
        WebView(webPage)
            .webViewContentBackground(.hidden)
            .webViewBackForwardNavigationGestures(.disabled)
            .allowsHitTesting(isInteractive)
            // Grid: render at design canvas then scale to cell.
            // Full-screen: no constraints — fills parent naturally.
            .frame(width: isGrid ? DESIGN_WIDTH : nil,
                   height: isGrid ? DESIGN_HEIGHT : nil)
            .scaleEffect(isGrid ? s : 1, anchor: .topLeading)
            .frame(width: displayWidth, height: dh, alignment: .topLeading)
            .onAppear { webPage.load(html: renderedHTML) }
            .onDisappear {
                if isLazy { webPage.load(URLRequest(url: URL(string: "about:blank")!)) }
            }
            .onChange(of: changeToken) { _, _ in webPage.load(html: renderedHTML) }
    }
}

// MARK: - iOS 18: Raw WKWebView (UIViewRepresentable, zero transforms)

/// Barebone UIViewRepresentable — no transforms, no scaling applied internally.
/// All geometry work happens on the SwiftUI side in `LegacyProjectWebView`.
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

// MARK: - iOS 18: SwiftUI wrapper with scaling

/// Grid thumbnails: renders at design canvas and scales to `displayWidth`.
/// Full-screen (displayWidth == nil): fills parent naturally, no constraints.
private struct LegacyProjectWebView: View {
    let renderedHTML: String
    let changeToken: String
    let isInteractive: Bool
    let displayWidth: CGFloat?

    var body: some View {
        let isGrid = displayWidth != nil
        let s = displayWidth?.gridScale ?? 1
        let dh = displayWidth?.previewHeight
        RawWKWebView(
            renderedHTML: renderedHTML,
            changeToken: changeToken,
            isInteractive: isInteractive
        )
        // Grid: render at design canvas then scale to cell.
        // Full-screen: no constraints — fills parent naturally.
        .frame(width: isGrid ? DESIGN_WIDTH : nil,
               height: isGrid ? DESIGN_HEIGHT : nil)
        .scaleEffect(isGrid ? s : 1, anchor: .topLeading)
        .frame(width: displayWidth, height: dh, alignment: .topLeading)
    }
}
