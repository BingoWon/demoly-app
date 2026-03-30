//
//  SearchSheet.swift
//  Demoly
//
//  Search projects and creators
//

import SwiftUI

// MARK: - Shared Search Content (used by Tab and Sheet)

struct SearchContentView: View {
    @State private var viewModel = SearchViewModel()
    @State private var selectedProject: Project?
    @State private var containerWidth: CGFloat = 320

    var body: some View {
        ZStack {
            Color.clear

            if viewModel.searchQuery.isEmpty {
                trendingContent
            } else {
                searchResults
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchQuery, prompt: "Projects, creators, #tags...")
        .navigationDestination(item: $selectedProject) { project in
            ProjectViewerPage(project: project)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { containerWidth = $0 }
        .task {
            await viewModel.loadTrending()
        }
    }

    // MARK: - Trending Content

    private var trendingContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if viewModel.isLoadingTrending {
                    loadingState
                } else {
                    trendingSection
                }
            }
            .padding(16)
        }
    }

    private var loadingState: some View {
        VStack {
            Spacer()
            ProgressView()
                .frame(maxWidth: .infinity)
            Spacer()
        }
        .frame(minHeight: 200)
    }

    // MARK: - Trending Tags

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            trendingLabel

            FlowLayout(spacing: 8) {
                ForEach(viewModel.trendingTags, id: \.self) { tag in
                    Button {
                        viewModel.searchTag(tag)
                    } label: {
                        Text("#\(tag)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.brand)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.brand.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var trendingLabel: some View {
        let label = Label("Trending", systemImage: "flame.fill")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.primary)

        if #available(iOS 26.0, *) {
            label.labelIconToTitleSpacing(8)
        } else {
            label
        }
    }

    // MARK: - Search Results

    private var searchResults: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if viewModel.isSearching {
                    searchingIndicator
                } else if viewModel.projects.isEmpty, viewModel.users.isEmpty {
                    emptyResults
                } else {
                    if !viewModel.users.isEmpty {
                        usersResults
                    }
                    if !viewModel.projects.isEmpty {
                        projectsResults
                    }
                }
            }
        }
    }

    private var searchingIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding(.vertical, 40)
            Spacer()
        }
    }

    private var emptyResults: some View {
        ContentUnavailableView.search(text: viewModel.searchQuery)
    }

    // MARK: - Users Results

    private var usersResults: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Creators")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            ForEach(viewModel.users) { user in
                NavigationLink {
                    UserProfileView(username: user.handle)
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.brand)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(user.initial)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.displayName ?? user.handle)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.primary)
                            Text("@\(user.handle)")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }

            Divider()
                .padding(.vertical, 8)
        }
    }

    // MARK: - Projects Results

    private var projectsResults: some View {
        let (columns, columnWidth) = GridMetrics.compute(
            width: containerWidth - 32,
            minColumnWidth: GridMetrics.feedMinColumnWidth,
            spacing: GridMetrics.feedSpacing
        )
        return VStack(alignment: .leading, spacing: 0) {
            Text("Projects")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            MasonryGrid(
                projects: viewModel.projects,
                columns: columns,
                columnWidth: columnWidth,
                spacing: GridMetrics.feedSpacing
            ) { project in
                Button { selectedProject = project } label: {
                    ProjectGridCell(project: project, columnWidth: columnWidth)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
    }
}


// MARK: - Sheet Wrapper (iOS 18 / non-tab contexts)

struct SearchSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SearchContentView()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        SheetCloseButton { dismiss() }
                    }
                }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    SearchSheet()
        .environment(AuthManager())
}
