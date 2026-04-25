//
//  FeedView.swift
//  Demoly
//
//  Grid-based discover page with native navigation
//

import SwiftUI

struct FeedView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSearch = false
    @State private var selectedProject: Project?
    @State private var containerWidth: CGFloat = UIScreen.main.bounds.width

    private let feed = FeedViewModel.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                gridView
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .navigationDestination(item: $selectedProject) { project in
                ProjectViewerPage(project: project)
            }
        }
        .sheet(isPresented: $showSearch) {
            SearchSheet()
        }
        .task {
            feed.loadInitial()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                feed.retryIfNeeded()
            }
        }
    }

    // MARK: - Grid View

    private var gridView: some View {
        let (columns, columnWidth) = GridMetrics.compute(
            width: containerWidth,
            minColumnWidth: GridMetrics.feedMinColumnWidth,
            spacing: GridMetrics.feedSpacing
        )

        return ScrollView {
            if feed.isLoading, feed.projects.isEmpty {
                loadingState
            } else if let error = feed.error, feed.projects.isEmpty {
                NetworkErrorView(message: error) {
                    feed.loadInitial()
                }
            } else if feed.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: GridMetrics.gridItems(columns: columns, spacing: 4), spacing: 4) {
                    ForEach(feed.projects) { project in
                        Button { selectedProject = project } label: {
                            ProjectGridCell(project: project, columnWidth: columnWidth)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, 4)
            }
        }
        .refreshable { await feed.refresh() }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            containerWidth = newWidth
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Discover")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)
        }

        if #available(iOS 26.0, *) {
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
        } else {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(.primary)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No projects yet", systemImage: "sparkles")
        } description: {
            Text("Be the first to create!")
        }
    }
}

// MARK: - Grid Cell

struct ProjectGridCell: View {
    let project: Project
    let columnWidth: CGFloat

    private var cellHeight: CGFloat {
        max(columnWidth / GridMetrics.previewAspectRatio, 1)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ProjectWebView(project: project, displayWidth: columnWidth)
                .clipped()

            // Transparent overlay claims the full hit area for SwiftUI
            // so touches never fall into the underlying WKWebView
            Color.clear
                .contentShape(RoundedRectangle(cornerRadius: 12))

            LikeButton(projectId: project.id, size: .compact)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .glassBackground()
                .padding(8)
        }
        .frame(width: columnWidth, height: cellHeight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Like Button

struct LikeButton: View {
    let projectId: String
    var size: Size = .regular

    @Environment(AuthManager.self) private var authManager
    private let store = InteractionStore.shared

    enum Size {
        case compact, regular

        var iconSize: CGFloat {
            switch self {
            case .compact: 13
            case .regular: 16
            }
        }

        var textSize: CGFloat {
            switch self {
            case .compact: 13
            case .regular: 14
            }
        }
    }

    var body: some View {
        Button {
            authManager.requireLogin {
                Task { await store.toggleLike(projectId: projectId) }
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: store.isLiked(projectId) ? "heart.fill" : "heart")
                    .font(.system(size: size.iconSize))
                    .symbolEffect(.bounce, value: store.isLiked(projectId))
                Text(store.likeCount(projectId).formatted)
                    .font(.system(size: size.textSize))
            }
            .foregroundStyle(store.isLiked(projectId) ? .red : .secondary)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .frame(minWidth: 44, minHeight: 28)
    }
}

#Preview {
    FeedView()
        .environment(AuthManager())
}
