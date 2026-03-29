//
//  ProjectViewerPage.swift
//  Demoly
//
//  Full-screen project viewer with Liquid Glass toolbar
//

import SwiftUI

struct ProjectViewerPage: View {
    let project: Project
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var showComments = false
    @State private var showDetail = false

    private let store = InteractionStore.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            projectContent

            FloatingProjectAccessory(
                showDetail: $showDetail,
                onLike: { authManager.requireLogin { toggleLike() } },
                onComment: { showComments = true },
                onCollect: { authManager.requireLogin { toggleCollect() } },
                onShare: nil  // Handled internally by ShareLink
            )
        }
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showComments) {
            CommentSheet(project: project)
        }
        .sheet(isPresented: $showDetail) {
            ProjectDetailSheet(project: project)
        }
    }

    @ViewBuilder
    private var projectContent: some View {
        let webView = ProjectWebView(project: project)
            // Removed .id(feed.currentIndex) entirely to avoid dependency
            .ignoresSafeArea()

        if #available(iOS 26.0, *) {
            webView.backgroundExtensionEffect()
        } else {
            webView
        }
    }

    // MARK: - Actions

    private func toggleLike() {
        Task { await store.toggleLike(projectId: project.id) }
    }

    private func toggleCollect() {
        Task { await store.toggleCollect(projectId: project.id) }
    }
}

// Removed ViewerToolbarModifier since interactions are now in the bottom floating accessory.

// MARK: - App Feed Pager View (TikTok Style Container)

struct FeedPagerView: View {
    let initialProject: Project
    @Environment(\.dismiss) private var dismiss

    private let feed = FeedViewModel.shared
    @State private var scrolledID: String?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(feed.projects) { project in
                    ProjectViewerPage(project: project)
                        .id(project.id)
                        .containerRelativeFrame([.horizontal, .vertical])
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrolledID)
        .ignoresSafeArea()
        .overlay(alignment: .topLeading) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            .padding(.leading, 16)
            .padding(.top, 56)  // Account for safe area
        }
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
        // Completely hide the default navigation and tab bars for immersive experience
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }
}
#Preview {
    NavigationStack {
        ProjectViewerPage(project: .sample)
    }
    .environment(AuthManager())
}
