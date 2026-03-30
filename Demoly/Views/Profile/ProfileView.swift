//
//  ProfileView.swift
//  Demoly
//

import ClerkKit
import SwiftUI

struct ProfileView: View {
    @Environment(AuthManager.self) private var authManager
    let editProject: (Project) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if Clerk.shared.user != nil {
                    ProfileContentView(editProject: editProject)
                } else {
                    signInPrompt
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var signInPrompt: some View {
        SignInPromptView(icon: "person.circle", message: "Sign in to see your profile")
    }
}

// MARK: - Profile Content View

struct ProfileContentView: View {
    let editProject: (Project) -> Void

    private var userProfile: CurrentUserProfile {
        CurrentUserProfile.shared
    }

    @State private var showSettings = false
    @State private var showEditProfile = false

    var body: some View {
        GeometryReader { geometry in
            let (columns, columnWidth) = GridMetrics.profileLayout(
                width: geometry.size.width
            )

            ScrollView {
                VStack(spacing: 8) {
                    ProfileHeaderView(
                        profile: userProfile.profile,
                        showEditButton: true,
                        onEditTapped: { showEditProfile = true }
                    )

                    ProfileStatsRow(
                        projectCount: userProfile.projectCount,
                        followerCount: userProfile.followerCount,
                        followingCount: userProfile.followingCount
                    )

                    projectGrid(columns: columns, columnWidth: columnWidth)
                }
            }
            .refreshable { await userProfile.refresh() }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .task { await userProfile.refresh() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showEditProfile) { EditProfileView(profile: userProfile.profile) }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - Project Grid

    @ViewBuilder
    private func projectGrid(columns: Int, columnWidth: CGFloat) -> some View {
        if userProfile.projects.isEmpty {
            ContentUnavailableView {
                Label("No projects created yet", systemImage: "square.grid.2x2")
            }
            .padding(.vertical, 40)
        } else {
            MasonryGrid(
                projects: userProfile.projects,
                columns: columns,
                columnWidth: columnWidth,
                spacing: 2
            ) { project in
                Button { editProject(project) } label: {
                    ProfileProjectCell(project: project, columnWidth: columnWidth, showDraftBadge: !project.isPublished)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)
        }
    }
}

// MARK: - Profile Project Cell

struct ProfileProjectCell: View {
    let project: Project
    let columnWidth: CGFloat
    var showDraftBadge = false

    private var cellHeight: CGFloat {
        max(columnWidth / GridMetrics.previewAspectRatio, 1)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ProjectWebView(project: project, isInteractive: false, isLazy: true)
                .frame(width: columnWidth, height: cellHeight)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            if showDraftBadge {
                Text("Draft")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .padding(3)
            }
        }
    }
}

#Preview {
    ProfileView(editProject: { _ in })
        .environment(AuthManager())
}
