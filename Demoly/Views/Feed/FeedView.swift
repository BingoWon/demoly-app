//
//  FeedView.swift
//  Demoly
//
//  Xiaohongshu-style masonry grid discover page with native navigation
//

import SwiftUI

struct FeedView: View {
    @State private var showSearch = false
    @State private var selectedProject: Project?

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
    }

    // MARK: - Grid View

    private var gridView: some View {
        GeometryReader { geometry in
            let (columns, columnWidth) = GridMetrics.compute(
                width: geometry.size.width,
                minColumnWidth: 170,
                spacing: 4
            )

            ScrollView {
                if feed.isLoading, feed.projects.isEmpty {
                    loadingState
                } else if feed.isEmpty {
                    emptyState
                } else {
                    MasonryGrid(
                        projects: feed.projects,
                        columns: columns,
                        columnWidth: columnWidth,
                        infoHeight: 60,
                        spacing: 4
                    ) { project in
                        ProjectGridCell(project: project, columnWidth: columnWidth)
                            .onTapGesture { selectedProject = project }
                    }
                    .padding(.top, 4)
                }
            }
            .refreshable { await feed.refresh() }
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

    private var imageHeight: CGFloat {
        max(columnWidth / Thumbnail.aspectRatio, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CachedThumbnail(project: project, size: CGSize(width: columnWidth, height: imageHeight))

            VStack(alignment: .leading, spacing: 3) {
                Text(project.displayTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.brand)
                        .frame(width: 18, height: 18)
                        .overlay {
                            Text(project.creator?.initial ?? "U")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                        }

                    Text(project.creator?.displayName ?? project.creator?.handle ?? "User")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer()

                    LikeButton(projectId: project.id, size: .compact)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 5)
        }
        .frame(width: columnWidth)
        .background(Color.secondaryBackground)
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
