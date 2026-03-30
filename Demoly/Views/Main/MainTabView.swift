//
//  MainTabView.swift
//  Demoly
//

import ClerkKit
import SwiftUI

struct MainTabView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var selectedTab = 0
    @State private var previousTab = 0
    @State private var projectEditor: ProjectEditorViewModel
    @State private var chatViewModel: ChatViewModel
    @State private var createSubTab: CreateSubTab = .chat
    @State private var unreadCount = 0

    init() {
        let editor = ProjectEditorViewModel()
        _projectEditor = State(initialValue: editor)
        _chatViewModel = State(initialValue: ChatViewModel(projectEditor: editor))
    }

    var body: some View {
        tabContent
            .tint(.primary)
            .task {
                await loadUnreadCount()
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                handleTabChange(from: oldValue, to: newValue)
            }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        if #available(iOS 26.0, *) {
            TabView(selection: $selectedTab) {
                Tab("Home", systemImage: "house.fill", value: 0) {
                    FeedView()
                }
                Tab("Create", systemImage: "wand.and.stars", value: 1) {
                    NavigationStack {
                        CreateView(
                            projectEditor: projectEditor,
                            chatViewModel: chatViewModel,
                            selectedSubTab: $createSubTab,
                            onBack: closeCreate
                        )
                    }
                    .environment(authManager)
                    .toolbar(.hidden, for: .tabBar)
                }
                Tab("Inbox", systemImage: "bell.fill", value: 2) {
                    InboxView()
                }
                .badge(unreadCount)
                Tab("Profile", systemImage: "person.fill", value: 3) {
                    ProfileView(editProject: editProject)
                }
                Tab("Search", systemImage: "magnifyingglass", value: 4, role: .search) {
                    NavigationStack {
                        SearchContentView()
                    }
                }
            }
            .tabViewStyle(.sidebarAdaptable)
            .tabBarMinimizeBehavior(.onScrollDown)
        } else {
            TabView(selection: $selectedTab) {
                FeedView()
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(0)
                NavigationStack {
                    CreateView(
                        projectEditor: projectEditor,
                        chatViewModel: chatViewModel,
                        selectedSubTab: $createSubTab,
                        onBack: closeCreate
                    )
                }
                .environment(authManager)
                .toolbar(.hidden, for: .tabBar)
                .tabItem { Label("Create", systemImage: "wand.and.stars") }
                .tag(1)
                InboxView()
                    .tabItem { Label("Inbox", systemImage: "bell.fill") }
                    .tag(2)
                    .badge(unreadCount)
                ProfileView(editProject: editProject)
                    .tabItem { Label("Profile", systemImage: "person.fill") }
                    .tag(3)
            }
        }
    }

    // MARK: - Actions

    private func handleTabChange(from oldValue: Int, to newValue: Int) {
        if newValue == 1 {
            if oldValue != 1 {
                previousTab = oldValue
            }
        }

        if newValue == 2 {
            Task { await loadUnreadCount() }
        }
    }

    private func closeCreate() {
        let needsSave = projectEditor.hasContent && projectEditor.isDirty
        Task {
            await projectEditor.saveAndReset()
            if needsSave {
                await CurrentUserProfile.shared.refresh()
                FeedViewModel.shared.markNeedsRefresh()
            }
        }
        chatViewModel.clear()
        createSubTab = .chat

        selectedTab = previousTab == 1 ? 0 : previousTab
    }

    private func editProject(_ project: Project) {
        projectEditor.load(project: project)
        chatViewModel.loadFromProjectEditor()
        createSubTab = .preview

        if selectedTab != 1 {
            previousTab = selectedTab
        }
        selectedTab = 1
    }

    private func loadUnreadCount() async {
        guard Clerk.shared.user != nil else {
            unreadCount = 0
            return
        }
        do {
            unreadCount = try await ActivityService.shared.fetchUnreadCount()
        } catch {
            print("Failed to load unread count: \(error)")
        }
    }
}

#Preview {
    MainTabView()
        .environment(AuthManager())
}
