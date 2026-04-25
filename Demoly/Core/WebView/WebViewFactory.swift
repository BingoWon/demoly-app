//
//  WebViewFactory.swift
//  Demoly
//
//  Single source of truth for chromeless WKWebView creation. Pool, thumbnail
//  and editor preview all rely on the same configuration.
//

import WebKit

enum WebViewFactory {
    static func make(scrollable: Bool = false, interactive: Bool = true) -> WKWebView {
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
        webView.scrollView.isScrollEnabled = scrollable
        webView.isUserInteractionEnabled = interactive
        return webView
    }
}
