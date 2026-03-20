//
//  ProjectEditorViewModel.swift
//  Demoly
//

import ClerkKit
import SwiftUI
import WebKit

@MainActor
@Observable
final class ProjectEditorViewModel {
    // MARK: - Default Templates

    static let defaultHTML = """
        <div class="container">
          <h1>Hello, World!</h1>
          <p>Start creating your masterpiece</p>
        </div>
        """

    static let defaultCSS = """
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }

        body {
          min-height: 100vh;
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

    static let defaultJS = """
        // Add interactivity here
        """

    // MARK: - Identity

    var projectId: String?

    // MARK: - Content

    var html = defaultHTML {
        didSet { if html != oldValue { markDirty() } }
    }

    var css = defaultCSS {
        didSet { if css != oldValue { markDirty() } }
    }

    var javascript = defaultJS {
        didSet { if javascript != oldValue { markDirty() } }
    }

    // MARK: - Chat

    var chatMessages: [[String: Any]] = []

    // MARK: - Metadata

    var title = "" {
        didSet { if title != oldValue { markDirty() } }
    }

    var description = "" {
        didSet { if description != oldValue { markDirty() } }
    }

    var tags: [String] = [] {
        didSet { if tags != oldValue { markDirty() } }
    }

    var isPublished = false {
        didSet { if isPublished != oldValue { markDirty() } }
    }

    // MARK: - Thumbnail

    var thumbnailUrl: String?
    var thumbnailAspectRatio: CGFloat?
    var thumbnailImage: UIImage?
    var isCapturingThumbnail = false

    weak var previewWebView: WKWebView?

    // MARK: - State

    private var isLoading = false
    var isDirty = false {
        didSet { if isDirty, !oldValue, !isLoading { scheduleAutoSave() } }
    }

    var isSaving = false
    var lastSaved: Date?
    var saveError: Error?

    // MARK: - Computed

    var hasCustomCode: Bool {
        (html != Self.defaultHTML && !html.isEmpty)
            || (css != Self.defaultCSS && !css.isEmpty)
            || (javascript != Self.defaultJS && !javascript.isEmpty)
    }

    var hasMetadata: Bool {
        !title.isEmpty || !description.isEmpty || !tags.isEmpty
    }

    var hasChat: Bool {
        chatMessages.contains { ($0["role"] as? String) != "system" }
    }

    var hasContent: Bool {
        hasChat || hasMetadata || hasCustomCode
    }

    var isNew: Bool {
        projectId == nil
    }

    var hasThumbnail: Bool {
        thumbnailUrl != nil || thumbnailImage != nil
    }

    var smallThumbnailURL: URL? {
        guard let thumbnailUrl else { return nil }
        if thumbnailUrl.hasPrefix("http") { return URL(string: thumbnailUrl) }
        return URL(string: "\(Config.hostURL)\(thumbnailUrl)")
    }

    // MARK: - Thumbnail Actions

    func captureThumbnail(aspectRatio: ThumbnailAspectRatio) async {
        guard let webView = previewWebView else { return }

        isCapturingThumbnail = true
        defer { isCapturingThumbnail = false }

        do {
            let cropped = try await ThumbnailService.shared.capture(from: webView, aspectRatio: aspectRatio)
            thumbnailImage = cropped
            thumbnailAspectRatio = cropped.size.width / cropped.size.height
            isDirty = true
        } catch {
            saveError = error
        }
    }

    func setThumbnail(image: UIImage, aspectRatio: ThumbnailAspectRatio) {
        let cropped = ThumbnailService.cropToRatio(image, targetRatio: aspectRatio.ratio)
        thumbnailImage = cropped
        thumbnailAspectRatio = cropped.size.width / cropped.size.height
        isDirty = true
    }

    func removeThumbnail() {
        thumbnailImage = nil
        thumbnailUrl = nil
        thumbnailAspectRatio = nil
        isDirty = true
    }

    // MARK: - Save

    func save() async {
        guard hasContent, Clerk.shared.user != nil else { return }

        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            let payload = ProjectService.CreateProjectPayload(
                title: title,
                description: description.isEmpty ? nil : description,
                tags: tags,
                htmlContent: html,
                cssContent: css,
                jsContent: javascript,
                chatMessages: chatMessages.isEmpty ? nil : chatMessages.map { $0.mapValues { AnyCodable($0) } },
                isPublished: isPublished,
                thumbnailUrl: thumbnailUrl,
                thumbnailAspectRatio: thumbnailAspectRatio.map { Double($0) }
            )

            let effectiveProjectId: String
            if let existingId = projectId {
                effectiveProjectId = existingId
                _ = try await ProjectService.shared.updateProject(id: existingId, payload: payload)
            } else {
                let created = try await ProjectService.shared.createProject(payload: payload)
                effectiveProjectId = created.id
                projectId = effectiveProjectId
            }

            if let image = thumbnailImage {
                let result = try await ThumbnailService.shared.upload(image: image, projectId: effectiveProjectId)
                thumbnailUrl = result.url
                thumbnailAspectRatio = result.aspectRatio
                thumbnailImage = nil
            }

            isDirty = false
            lastSaved = Date()
        } catch {
            saveError = error
        }
    }

    func saveAndReset() async {
        if hasContent, isDirty { await save() }
        reset()
    }

    // MARK: - Reset & Load

    func reset() {
        autoSaveTask?.cancel()
        autoSaveTask = nil
        projectId = nil
        html = Self.defaultHTML
        css = Self.defaultCSS
        javascript = Self.defaultJS
        chatMessages = []
        title = ""
        description = ""
        tags = []
        isPublished = false
        thumbnailUrl = nil
        thumbnailAspectRatio = nil
        thumbnailImage = nil
        isDirty = false
        lastSaved = nil
        saveError = nil
        previewWebView = nil
    }

    func load(project: Project) {
        autoSaveTask?.cancel()
        autoSaveTask = nil
        isLoading = true
        defer {
            isLoading = false
            isDirty = false
        }
        projectId = project.id
        title = project.title
        description = project.description ?? ""
        tags = project.tags ?? []
        html = project.htmlContent ?? ""
        css = project.cssContent ?? ""
        javascript = project.jsContent ?? ""
        chatMessages = project.chatMessages ?? []
        isPublished = project.isPublished
        thumbnailUrl = project.thumbnailUrl
        thumbnailAspectRatio = project.thumbnailAspectRatio
        thumbnailImage = nil
        lastSaved = project.updatedAt
    }

    // MARK: - Auto-Save

    private var autoSaveTask: Task<Void, Never>?
    private let autoSaveDelay: UInt64 = 2_000_000_000

    func markDirty() {
        isDirty = true
    }

    private func scheduleAutoSave() {
        autoSaveTask?.cancel()
        autoSaveTask = Task {
            do {
                try await Task.sleep(nanoseconds: autoSaveDelay)
                guard !Task.isCancelled, hasContent, isDirty, !isSaving else { return }
                await save()
            } catch {}
        }
    }
}
