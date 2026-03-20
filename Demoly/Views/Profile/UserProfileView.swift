//
//  UserProfileView.swift
//  Demoly
//
//  View other user's profile
//

import SwiftUI

struct UserProfileView: View {
    let username: String
    @State private var viewModel: OtherUserProfileViewModel

    init(username: String) {
        self.username = username
        _viewModel = State(initialValue: OtherUserProfileViewModel(username: username))
    }

    var body: some View {
        GeometryReader { geometry in
            let columnWidth = max((geometry.size.width - 8) / 3, 1)

            ScrollView {
                VStack(spacing: 8) {
                    ProfileHeaderView(profile: viewModel.profile, isLoading: viewModel.isLoading)

                    ProfileStatsRow(
                        projectCount: viewModel.projectCount,
                        followerCount: viewModel.followerCount,
                        followingCount: viewModel.followingCount,
                        isLoading: viewModel.isLoading
                    )

                    actionButtons

                    projectMasonryGrid(columnWidth: columnWidth)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        if !viewModel.isSelf {
            HStack(spacing: 12) {
                Button {
                    Task { await viewModel.toggleFollow() }
                } label: {
                    Text(viewModel.isFollowing ? "Following" : "Follow")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(viewModel.isFollowing ? Color.primary : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(viewModel.isFollowing ? Color.secondaryBackground : Color.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Project Masonry Grid

    private func projectMasonryGrid(columnWidth: CGFloat) -> some View {
        Group {
            if viewModel.projects.isEmpty, !viewModel.isLoading {
                ContentUnavailableView {
                    Label("No projects yet", systemImage: "square.grid.2x2")
                }
                .padding(.vertical, 40)
            } else {
                MasonryGrid(projects: viewModel.projects, columnWidth: columnWidth, columns: 3, spacing: 2) { project in
                    ProfileProjectCell(project: project, columnWidth: columnWidth)
                }
                .padding(.top, 2)
            }
        }
    }
}

#Preview {
    NavigationStack {
        UserProfileView(username: "creator")
    }
    .environment(AuthManager())
}
