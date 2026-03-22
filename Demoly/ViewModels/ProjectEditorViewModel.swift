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
    // MARK: - Default Templates (fetched from backend via AIConfig)

    static var defaultHTML: String { AIConfig.shared.defaultHTML }
    static var defaultCSS: String { AIConfig.shared.defaultCSS }
    static var defaultJS: String { AIConfig.shared.defaultJS }

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

    // MARK: - Thumbnail (auto-managed)

    var thumbnailUrl: String?
    var thumbnailAspectRatio: CGFloat?

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

            // Auto-capture thumbnail from preview after save
            if let webView = previewWebView {
                do {
                    let result = try await ThumbnailService.shared.captureAndUpload(from: webView, projectId: effectiveProjectId)
                    thumbnailUrl = result.url
                    thumbnailAspectRatio = result.aspectRatio
                } catch {
                    print("[ProjectEditor] Thumbnail auto-capture failed: \(error.localizedDescription)")
                }
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
