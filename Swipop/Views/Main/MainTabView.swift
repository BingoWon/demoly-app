//
//  MainTabView.swift
//  Swipop
//

import ClerkKit
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @State private var projectEditor: ProjectEditorViewModel
    @State private var chatViewModel: ChatViewModel
    @State private var createSubTab: CreateSubTab = .chat
    @State private var showingCreate = false
    @State private var unreadCount = 0
    @State private var feedRefreshTrigger = 0
    @State private var inboxRefreshTrigger = 0
    @State private var profileRefreshTrigger = 0

    init() {
        let editor = ProjectEditorViewModel()
        _projectEditor = State(initialValue: editor)
        _chatViewModel = State(initialValue: ChatViewModel(projectEditor: editor))
    }

    private var homeTab: some View {
        FeedView(refreshTrigger: feedRefreshTrigger)
    }

    private var createPlaceholder: some View {
        Color.appBackground.ignoresSafeArea()
    }

    private var inboxTab: some View {
        InboxView(refreshTrigger: inboxRefreshTrigger)
    }

    private var profileTab: some View {
        ProfileView(editProject: editProject, refreshTrigger: profileRefreshTrigger)
    }

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                iOS26Content
            } else {
                iOS18Content
            }
        }
        .tint(.primary)
        .fullScreenCover(isPresented: $showingCreate) {
            NavigationStack {
                CreateView(
                    projectEditor: projectEditor,
                    chatViewModel: chatViewModel,
                    selectedSubTab: $createSubTab,
                    onBack: closeCreate
                )
            }
            .tint(.primary)
        }
        .task {
            await loadUnreadCount()
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            handleTabChange(from: oldValue, to: newValue)
        }
        .onChange(of: showingCreate) { _, isShowing in
            if !isShowing, selectedTab == 1 {
                selectedTab = previousTab
            }
        }
    }

    // MARK: - iOS 26

    @available(iOS 26.0, *)
    private var iOS26Content: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) { homeTab }
            Tab("Create", systemImage: "wand.and.stars", value: 1) { createPlaceholder }
            Tab("Inbox", systemImage: "bell.fill", value: 2) { inboxTab }
                .badge(unreadCount)
            Tab("Profile", systemImage: "person.fill", value: 3) { profileTab }
        }
    }

    // MARK: - iOS 18

    private var iOS18Content: some View {
        TabView(selection: $selectedTab) {
            homeTab
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            createPlaceholder
                .tabItem { Label("Create", systemImage: "wand.and.stars") }
                .tag(1)
            inboxTab
                .tabItem { Label("Inbox", systemImage: "bell.fill") }
                .tag(2)
                .badge(unreadCount)
            profileTab
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(3)
        }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }

    // MARK: - Actions

    private func handleTabChange(from oldValue: Int, to newValue: Int) {
        if newValue == 1 {
            previousTab = oldValue
            showingCreate = true
        }

        switch newValue {
        case 0: feedRefreshTrigger += 1
        case 2:
            inboxRefreshTrigger += 1
            Task { await loadUnreadCount() }
        case 3: profileRefreshTrigger += 1
        default: break
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
        showingCreate = false
    }

    private func editProject(_ project: Project) {
        projectEditor.load(project: project)
        chatViewModel.loadFromProjectEditor()
        createSubTab = .preview
        showingCreate = true
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
