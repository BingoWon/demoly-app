//
//  ProjectPreviewView.swift
//  Demoly
//
//  Live preview of the project being edited.
//  Uses ProjectWebView(html:css:javascript:) directly — no separate WebView wrapper needed.
//  Content is re-rendered via .id(contentHash) whenever code changes.
//

import SwiftUI

struct ProjectPreviewView: View {
    @Bindable var projectEditor: ProjectEditorViewModel

    private var isEmpty: Bool {
        projectEditor.html.isEmpty && projectEditor.css.isEmpty && projectEditor.javascript.isEmpty
    }

    /// Changes when any code field changes, causing ProjectWebView to rebuild.
    private var contentHash: Int {
        var hasher = Hasher()
        hasher.combine(projectEditor.html)
        hasher.combine(projectEditor.css)
        hasher.combine(projectEditor.javascript)
        return hasher.finalize()
    }

    var body: some View {
        if isEmpty {
            emptyState
        } else {
            ProjectWebView(
                html: projectEditor.html,
                css: projectEditor.css,
                javascript: projectEditor.javascript
            )
            .id(contentHash)
            .ignoresSafeArea()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.slash")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("No preview available")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.secondary)

            Text("Start chatting to generate code")
                .font(.system(size: 14))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ProjectPreviewView(projectEditor: ProjectEditorViewModel())
}
