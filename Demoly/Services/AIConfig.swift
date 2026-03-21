//
//  AIConfig.swift
//  Demoly
//
//  Single source of truth for AI configuration, fetched from the backend.
//

import Foundation

@MainActor
final class AIConfig {
    static let shared = AIConfig()

    private(set) var systemPrompt: String
    private(set) var defaultHTML: String
    private(set) var defaultCSS: String
    private(set) var defaultJS: String

    private var loaded = false

    private init() {
        systemPrompt = Self.fallbackSystemPrompt
        defaultHTML = Self.fallbackHTML
        defaultCSS = Self.fallbackCSS
        defaultJS = Self.fallbackJS
    }

    func load() async {
        guard !loaded else { return }
        do {
            let config: AIConfigResponse = try await APIClient.shared.get("/ai/config")
            systemPrompt = config.systemPrompt
            defaultHTML = config.defaultHtml
            defaultCSS = config.defaultCss
            defaultJS = config.defaultJs
            loaded = true
        } catch {
            print("[AIConfig] Failed to load from backend, using fallbacks: \(error.localizedDescription)")
        }
    }
}

// MARK: - Response

private struct AIConfigResponse: Decodable {
    let systemPrompt: String
    let defaultHtml: String
    let defaultCss: String
    let defaultJs: String
}

// MARK: - Fallbacks

extension AIConfig {
    fileprivate static let fallbackSystemPrompt = """
        You are a creative AI assistant in Demoly, a social app for sharing HTML/CSS/JS creative projects.
        Help users create interactive, visually appealing web components.
        """

    fileprivate static let fallbackHTML = """
        <div class="container">
          <h1>Hello, World!</h1>
          <p>Start creating your masterpiece</p>
        </div>
        """

    fileprivate static let fallbackCSS = """
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }

        body {
          height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          background: linear-gradient(135deg, #1a1a2e, #16213e);
          font-family: system-ui, -apple-system, sans-serif;
        }

        .container {
          text-align: center;
          color: white;
        }

        h1 {
          font-size: 2.5rem;
          margin-bottom: 0.5rem;
        }

        p {
          opacity: 0.7;
        }
        """

    fileprivate static let fallbackJS = ""
}
