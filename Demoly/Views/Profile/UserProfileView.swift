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
    @State private var containerWidth: CGFloat = UIScreen.main.bounds.width

    init(username: String) {
        self.username = username
        _viewModel = State(initialValue: OtherUserProfileViewModel(username: username))
    }

    var body: some View {
        let (columns, columnWidth) = GridMetrics.profileLayout(
            width: containerWidth
        )

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

                projectGrid(columns: columns, columnWidth: columnWidth)
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            containerWidth = newWidth
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

    // MARK: - Project Grid

    private func projectGrid(columns: Int, columnWidth: CGFloat) -> some View {
        Group {
            if viewModel.projects.isEmpty, !viewModel.isLoading {
                ContentUnavailableView {
                    Label("No projects yet", systemImage: "square.grid.2x2")
                }
                .padding(.vertical, 40)
            } else {
                LazyVGrid(columns: GridMetrics.gridItems(columns: columns, spacing: 2), spacing: 2) {
                    ForEach(viewModel.projects) { project in
                        ProfileProjectCell(project: project, columnWidth: columnWidth)
                    }
                }
                .padding(.horizontal, 2)
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
