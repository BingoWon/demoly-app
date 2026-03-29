//
//  CreateView.swift
//  Demoly
//
//  Project creation/editing view with Liquid Glass toolbar
//

import ClerkKit
import ClerkKitUI
import SwiftUI

struct CreateView: View {
    @Environment(AuthManager.self) private var authManager
    @Bindable var projectEditor: ProjectEditorViewModel
    @Bindable var chatViewModel: ChatViewModel
    @Binding var selectedSubTab: CreateSubTab
    let onBack: () -> Void

    @State private var showOptions = false
    @State private var deleteError: String?
    @FocusState private var isInputFocused: Bool

    private var isSignedIn: Bool {
        Clerk.shared.user != nil
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground.ignoresSafeArea()

            if isSignedIn {
                content
                    .safeAreaInset(edge: .bottom) {
                        Spacer().frame(height: 60)
                    }
            } else {
                signInPrompt
            }

            if isSignedIn {
                FloatingCreateAccessory(selectedSubTab: $selectedSubTab)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onBack) {
                    Image(systemName: "xmark")
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                if isSignedIn {
                    if selectedSubTab.isCodeTab {
                        Button(action: { Task { await projectEditor.save() } }) {
                            HStack(spacing: 4) {
                                if projectEditor.isSaving {
                                    ProgressView().scaleEffect(0.7)
                                } else {
                                    Image(systemName: projectEditor.isDirty ? "circle.fill" : "checkmark")
                                        .font(.system(size: 10))
                                }
                                Text(projectEditor.isSaving ? "Saving" : projectEditor.isDirty ? "Save" : "Saved")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundStyle(projectEditor.isDirty ? .orange : .green)
                        }
                        .disabled(projectEditor.isSaving || !projectEditor.isDirty)
                    }

                    Button {
                        withAnimation(.interactive) {
                            projectEditor.isPublished.toggle()
                            projectEditor.isDirty = true
                        }
                    } label: {
                        Image(systemName: projectEditor.isPublished ? "eye" : "eye.slash")
                    }
                    .tint(projectEditor.isPublished ? .green : .orange)

                    Button {
                        showOptions = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showOptions) {
            ProjectOptionsSheet(projectEditor: projectEditor, chatViewModel: chatViewModel) {
                deleteProject()
            }
        }
        .alert(
            "Delete Failed",
            isPresented: .init(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteError ?? "")
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch selectedSubTab {
        case .chat:
            ChatEditorView(chatViewModel: chatViewModel, showSuggestions: true, isInputFocused: $isInputFocused)
        case .preview:
            ProjectPreviewView(projectEditor: projectEditor)
        case .html:
            RunestoneCodeView(language: .html, code: $projectEditor.html, isEditable: true)
                .ignoresSafeArea(edges: .bottom)
        case .css:
            RunestoneCodeView(language: .css, code: $projectEditor.css, isEditable: true)
                .ignoresSafeArea(edges: .bottom)
        case .javascript:
            RunestoneCodeView(language: .javascript, code: $projectEditor.javascript, isEditable: true)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func deleteProject() {
        guard let projectId = projectEditor.projectId else { return }
        projectEditor.reset()
        chatViewModel.clear()
        onBack()

        Task {
            do {
                try await ProjectService.shared.deleteProject(id: projectId)
                await CurrentUserProfile.shared.refresh()
                FeedViewModel.shared.markNeedsRefresh()
            } catch {
                deleteError = error.localizedDescription
            }
        }
    }

    // MARK: - Sign In Prompt

    private var signInPrompt: some View {
        VStack(spacing: 24) {
            Image(systemName: "plus.square.dashed")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Sign in to create")
                .font(.title2)
                .foregroundStyle(.primary)

            Button {
                authManager.showAuthSheet = true
            } label: {
                Text("Sign In")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.brand)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    CreateViewPreview()
}

private struct CreateViewPreview: View {
    @State private var projectEditor = ProjectEditorViewModel()
    @State private var chatViewModel: ChatViewModel?

    var body: some View {
        NavigationStack {
            if let chat = chatViewModel {
                CreateView(projectEditor: projectEditor, chatViewModel: chat, selectedSubTab: .constant(.chat), onBack: {})
            }
        }
        .environment(AuthManager())
        .onAppear {
            chatViewModel = ChatViewModel(projectEditor: projectEditor)
        }
    }
}
