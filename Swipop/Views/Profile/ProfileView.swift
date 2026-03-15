//
//  ProfileView.swift
//  Swipop
//

import ClerkKit
import SwiftUI

struct ProfileView: View {
    @Environment(AuthManager.self) private var authManager
    let editProject: (Project) -> Void
    var refreshTrigger = 0

    var body: some View {
        NavigationStack {
            Group {
                if Clerk.shared.user != nil {
                    ProfileContentView(editProject: editProject, refreshTrigger: refreshTrigger)
                } else {
                    signInPrompt
                }
            }
        }
    }

    private var signInPrompt: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Sign in to see your profile")
                .font(.title3)
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
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Profile Content View

struct ProfileContentView: View {
    let editProject: (Project) -> Void
    var refreshTrigger = 0

    private var userProfile: CurrentUserProfile {
        CurrentUserProfile.shared
    }

    @State private var showSettings = false
    @State private var showEditProfile = false

    var body: some View {
        GeometryReader { geometry in
            let columnWidth = max((geometry.size.width - 8) / 3, 1)

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

                    projectGrid(columnWidth: columnWidth)
                }
            }
            .refreshable { await userProfile.refresh() }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .task { await userProfile.refresh() }
        .onChange(of: refreshTrigger) { _, _ in
            guard refreshTrigger > 0 else { return }
            Task { await userProfile.refresh() }
        }
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
    private func projectGrid(columnWidth: CGFloat) -> some View {
        if userProfile.projects.isEmpty {
            ContentUnavailableView {
                Label("No projects created yet", systemImage: "square.grid.2x2")
            }
            .padding(.vertical, 40)
        } else {
            MasonryGrid(projects: userProfile.projects, columnWidth: columnWidth, columns: 3, spacing: 2) { project in
                ProfileProjectCell(project: project, columnWidth: columnWidth, showDraftBadge: !project.isPublished)
                    .onTapGesture { editProject(project) }
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

    private var imageHeight: CGFloat {
        let ratio = max(project.thumbnailAspectRatio ?? 0.75, 0.1)
        return max(columnWidth / ratio, 1)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            CachedThumbnail(project: project, size: CGSize(width: columnWidth, height: imageHeight))
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
    ProfileView(editProject: { _ in }, refreshTrigger: 0)
        .environment(AuthManager())
}
