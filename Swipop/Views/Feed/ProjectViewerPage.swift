//
//  ProjectViewerPage.swift
//  Swipop
//
//  Full-screen project viewer with Liquid Glass toolbar
//

import SwiftUI

struct ProjectViewerPage: View {
    let initialProject: Project
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var showComments = false
    @State private var showDetail = false

    private let feed = FeedViewModel.shared
    private let store = InteractionStore.shared

    init(project: Project) {
        initialProject = project
    }

    private var currentProject: Project {
        feed.currentProject ?? initialProject
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            projectContent

            FloatingProjectAccessory(showDetail: $showDetail)
        }
        .toolbar(.hidden, for: .tabBar)
        .modifier(
            ViewerToolbarModifier(
                projectId: currentProject.id,
                showComments: $showComments,
                onLike: { authManager.requireLogin { toggleLike() } },
                onCollect: { authManager.requireLogin { toggleCollect() } },
                project: currentProject
            )
        )
        .sheet(isPresented: $showComments) {
            CommentSheet(project: currentProject)
        }
        .sheet(isPresented: $showDetail) {
            ProjectDetailSheet(project: currentProject)
        }
        .onAppear {
            feed.setCurrentProject(initialProject)
        }
    }

    @ViewBuilder
    private var projectContent: some View {
        let webView = ProjectWebView(project: currentProject)
            .id(feed.currentIndex)
            .ignoresSafeArea()

        if #available(iOS 26.0, *) {
            webView.backgroundExtensionEffect()
        } else {
            webView
        }
    }

    // MARK: - Actions

    private func toggleLike() {
        Task { await store.toggleLike(projectId: currentProject.id) }
    }

    private func toggleCollect() {
        Task { await store.toggleCollect(projectId: currentProject.id) }
    }
}

// MARK: - Viewer Toolbar Modifier

private struct ViewerToolbarModifier: ViewModifier {
    let projectId: String
    @Binding var showComments: Bool
    let onLike: () -> Void
    let onCollect: () -> Void
    let project: Project

    private let store = InteractionStore.shared

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: onLike) {
                        Image(systemName: store.isLiked(projectId) ? "heart.fill" : "heart")
                            .symbolEffect(.bounce, value: store.isLiked(projectId))
                    }
                    .tint(store.isLiked(projectId) ? .red : .primary)

                    Button {
                        showComments = true
                    } label: {
                        Image(systemName: "bubble.right")
                    }

                    Button(action: onCollect) {
                        Image(systemName: store.isCollected(projectId) ? "bookmark.fill" : "bookmark")
                            .symbolEffect(.bounce, value: store.isCollected(projectId))
                    }
                    .tint(store.isCollected(projectId) ? .yellow : .primary)

                    ProjectShareLink(project: project) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        ProjectViewerPage(project: .sample)
    }
    .environment(AuthManager())
}
