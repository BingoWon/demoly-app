//
//  ProjectDetailSheet.swift
//  Swipop
//
//  Project details with creator info, stats, and source code
//

import ClerkKit
import SwiftUI

struct ProjectDetailSheet: View {
    let project: Project
    @Environment(AuthManager.self) private var authManager

    @Environment(\.dismiss) private var dismiss
    @State private var followState = FollowState()
    @State private var showComments = false
    @State private var showShareSheet = false
    @State private var showCreatorProfile = false
    @State private var selectedLanguage: CodeLanguage = .html
    @State private var codeCopied = false

    private let store = InteractionStore.shared
    private var creator: Profile? {
        project.creator
    }

    private var isSelf: Bool {
        Clerk.shared.user?.id == creator?.id
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    creatorSection
                    Divider().background(Color.border)
                    projectSection
                    Divider().background(Color.border)
                    actionsSection
                    Divider().background(Color.border)
                    sourceCodeSection
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle(project.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SheetCloseButton { dismiss() }
                }
            }
            .navigationDestination(isPresented: $showCreatorProfile) {
                if let handle = creator?.handle {
                    UserProfileView(username: handle)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .glassSheetBackground()
        .task {
            if let profile = creator {
                followState.isFollowing = profile.isFollowing ?? false
            }
        }
        .sheet(isPresented: $showComments) {
            CommentSheet(project: project)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(project: project)
        }
    }

    // MARK: - Creator Section

    private var creatorSection: some View {
        HStack(spacing: 12) {
            Button {
                showCreatorProfile = true
            } label: {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.brand)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Text(creator?.initial ?? "?")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("@\(creator?.handle ?? "unknown")")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)

                        if let bio = creator?.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            if !isSelf {
                Button {
                    requireLogin {
                        Task { await toggleFollow() }
                    }
                } label: {
                    Text(followState.isFollowing ? "Following" : "Follow")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(followState.isFollowing ? Color.primary : .white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(followState.isFollowing ? Color.secondaryBackground : Color.brand)
                        .clipShape(Capsule())
                }
                .disabled(followState.isLoading)
            }
        }
    }

    private var projectSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(project.displayTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)

            if let description = project.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            }

            Text(project.createdAt.timeAgo)
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
    }

    private var actionsSection: some View {
        HStack(spacing: 0) {
            StatActionTile(icon: "eye", count: project.viewCount, tint: .primary)

            StatActionTile(
                icon: store.isLiked(project.id) ? "heart.fill" : "heart",
                count: store.likeCount(project.id),
                tint: store.isLiked(project.id) ? .red : .primary
            ) {
                requireLogin { Task { await store.toggleLike(projectId: project.id) } }
            }

            StatActionTile(icon: "bubble.right", count: project.commentCount, tint: .primary) {
                showComments = true
            }

            StatActionTile(
                icon: store.isCollected(project.id) ? "bookmark.fill" : "bookmark",
                count: store.collectCount(project.id),
                tint: store.isCollected(project.id) ? .yellow : .primary
            ) {
                requireLogin { Task { await store.toggleCollect(projectId: project.id) } }
            }

            StatActionTile(icon: "square.and.arrow.up", count: project.shareCount, tint: .primary) {
                showShareSheet = true
            }
        }
    }

    private var sourceCodeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Picker("", selection: $selectedLanguage) {
                    ForEach(CodeLanguage.allCases, id: \.self) { lang in
                        Text(lang.rawValue).tag(lang)
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    copyCode()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: codeCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 13, weight: .medium))
                        Text(codeCopied ? "Copied" : "Copy")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(codeCopied ? .green : .secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.secondaryBackground, in: Capsule())
                }
                .buttonStyle(.plain)
                .fixedSize()
                .animation(.easeInOut(duration: 0.2), value: codeCopied)
            }

            GeometryReader { _ in
                RunestoneCodeView(language: selectedLanguage, code: currentCode)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.border, lineWidth: 1)
                    )
            }
            .frame(height: UIScreen.main.bounds.height * 2 / 3)
        }
        .padding(.horizontal, -20)
        .padding(.horizontal, 8)
    }

    private func copyCode() {
        UIPasteboard.general.string = currentCode
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        codeCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            codeCopied = false
        }
    }

    private var currentCode: String {
        switch selectedLanguage {
        case .html: project.htmlContent ?? "<!-- No HTML content -->"
        case .css: project.cssContent ?? "/* No CSS content */"
        case .javascript: project.jsContent ?? "// No JavaScript content"
        }
    }

    // MARK: - Actions

    private func toggleFollow() async {
        guard let creatorId = creator?.id,
            let currentUserId = Clerk.shared.user?.id,
            creatorId != currentUserId
        else { return }

        let wasFollowing = followState.isFollowing
        followState.isFollowing.toggle()

        do {
            if followState.isFollowing {
                try await UserService.shared.follow(userId: creatorId)
            } else {
                try await UserService.shared.unfollow(userId: creatorId)
            }
        } catch {
            followState.isFollowing = wasFollowing
            print("Failed to toggle follow: \(error)")
        }
    }

    private func requireLogin(action: @escaping () -> Void) {
        if Clerk.shared.user != nil {
            action()
        } else {
            authManager.showAuthSheet = true
        }
    }
}

// MARK: - Follow State

private struct FollowState {
    var isFollowing = false
    var isLoading = false
}

// MARK: - Stat Action Tile

private struct StatActionTile: View {
    let icon: String
    let count: Int
    var tint: Color = .primary
    var action: (() -> Void)?

    var body: some View {
        Group {
            if let action {
                Button(action: action) { content }
            } else {
                content
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var content: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(tint)
            Text(count.formatted)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ProjectDetailSheet(project: .sample)
        .environment(AuthManager())
}
