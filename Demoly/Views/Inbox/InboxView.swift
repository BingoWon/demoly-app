//
//  InboxView.swift
//  Demoly
//
//  Activity notifications center with navigation to projects/profiles
//

import ClerkKit
import SwiftUI

struct InboxView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = InboxViewModel()
    @State private var selectedActivity: Activity?

    var body: some View {
        NavigationStack {
            Group {
                if Clerk.shared.user != nil {
                    if viewModel.isLoading, viewModel.activities.isEmpty {
                        ProgressView().tint(.primary)
                    } else if viewModel.activities.isEmpty {
                        ContentUnavailableView {
                            Label("No Activity", systemImage: "bell.slash")
                        } description: {
                            Text("When someone interacts with your projects, you'll see it here.")
                        }
                    } else {
                        activityList
                    }
                } else {
                    signInPrompt
                }
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.hasUnread {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Mark all read") {
                            Task { await viewModel.markAllAsRead() }
                        }
                        .font(.system(size: 14))
                    }
                }
            }
            .navigationDestination(item: $selectedActivity) { activity in
                destinationView(for: activity)
            }
        }
        .task {
            if Clerk.shared.user != nil {
                await viewModel.loadActivities()
            }
        }
    }

    private var signInPrompt: some View {
        VStack(spacing: 24) {
            Image(systemName: "bell.slash")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Sign in to see your activity")
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Activity List

    private var activityList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.groupedActivities, id: \.title) { group in
                    Section {
                        ForEach(group.activities) { activity in
                            ActivityRow(activity: activity)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    handleActivityTap(activity)
                                }

                            if activity.id != group.activities.last?.id {
                                Divider().overlay(Color.border).padding(.leading, 68)
                            }
                        }
                    } header: {
                        sectionHeader(group.title)
                    }
                }
            }
        }
        .refreshable {
            await viewModel.loadActivities()
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Navigation

    private func handleActivityTap(_ activity: Activity) {
        Task { await viewModel.markAsRead(activity) }
        selectedActivity = activity
    }

    @ViewBuilder
    private func destinationView(for activity: Activity) -> some View {
        switch activity.type {
        case .follow:
            if let handle = activity.actor?.handle {
                UserProfileView(username: handle)
            }
        case .like, .comment, .collect:
            if let project = activity.project {
                ProjectViewerPage(project: project)
            } else if let handle = activity.actor?.handle {
                UserProfileView(username: handle)
            }
        }
    }
}

// MARK: - Activity Row

private struct ActivityRow: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.brand)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(activity.actor?.initial ?? "?")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    )

                Circle()
                    .fill(activity.type.color)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Image(systemName: activity.type.icon)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .offset(x: 2, y: 2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(
                    activity.type.message(
                        actorName: activity.actor?.handle ?? "Someone",
                        projectTitle: activity.project?.title
                    )
                )
                .font(.system(size: 14))
                .foregroundStyle(.primary)
                .lineLimit(2)

                Text(activity.timeAgo)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)

            if !activity.isRead {
                Circle()
                    .fill(Color.brand)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(activity.isRead ? Color.clear : Color.brand.opacity(0.05))
    }
}

#Preview {
    InboxView()
        .environment(AuthManager())
}
