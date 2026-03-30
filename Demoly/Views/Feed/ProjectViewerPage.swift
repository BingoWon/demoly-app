//
//  ProjectViewerPage.swift
//  Demoly
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

    @State private var scrolledID: String?

    private var projectContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(feed.projects) { proj in
                    let webView = ProjectWebView(project: proj)
                        .ignoresSafeArea()

                    if #available(iOS 26.0, *) {
                        webView.backgroundExtensionEffect()
                            .containerRelativeFrame([.horizontal, .vertical])
                    } else {
                        webView
                            .containerRelativeFrame([.horizontal, .vertical])
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrolledID)
        .ignoresSafeArea()
        .onAppear {
            if scrolledID == nil {
                scrolledID = initialProject.id
            }
        }
        .onChange(of: scrolledID) { _, newID in
            if let newID = newID, let idx = feed.projects.firstIndex(where: { $0.id == newID }) {
                feed.setCurrentProject(feed.projects[idx])

                // Infinite loading trigger
                if idx >= feed.projects.count - 3 {
                    feed.loadMore()
                }
            }
        }
        .onChange(of: feed.currentIndex) { _, newIndex in
            guard newIndex >= 0 && newIndex < feed.projects.count else { return }
            let targetID = feed.projects[newIndex].id
            if scrolledID != targetID {
                withAnimation {
                    scrolledID = targetID
                }
            }
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
