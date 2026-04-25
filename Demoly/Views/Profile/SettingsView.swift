//
//  SettingsView.swift
//  Demoly
//

import ClerkKit
import ClerkKitUI
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppearanceSettings.self) private var appearance
    @State private var showLogoutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var deleteError: String?

    var body: some View {
        @Bindable var appearance = appearance

        NavigationStack {
            List {
                if let user = Clerk.shared.user {
                    Section {
                        HStack(spacing: 12) {
                            UserButton()
                                .frame(width: 40, height: 40)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(
                                    {
                                        let name = [user.firstName, user.lastName]
                                            .compactMap { $0 }
                                            .joined(separator: " ")
                                        return name.isEmpty ? "User" : name
                                    }()
                                )
                                .font(.headline)

                                if let email = user.primaryEmailAddress?.emailAddress {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Label("Profile", systemImage: "person.circle")
                    }
                }

                Section {
                    Picker(selection: $appearance.mode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Label(mode.displayName, systemImage: mode.icon)
                                .tag(mode)
                        }
                    } label: {
                        Label("Theme", systemImage: "paintbrush")
                    }
                } header: {
                    Label("Appearance", systemImage: "paintbrush.pointed")
                }

                Section {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }

                    NavigationLink {
                        PrivacySettingsView()
                    } label: {
                        Label("Privacy", systemImage: "lock")
                    }
                } header: {
                    Label("Preferences", systemImage: "slider.horizontal.3")
                }

                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About Demoly", systemImage: "info.circle")
                    }

                    Link(destination: URL(string: "https://demoly.thebinwang.com/terms")!) {
                        HStack {
                            Label("Terms of Service", systemImage: "doc.text")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Link(destination: URL(string: "https://demoly.thebinwang.com/privacy")!) {
                        HStack {
                            Label("Privacy Policy", systemImage: "hand.raised")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Label("About", systemImage: "info.circle")
                }

                if Clerk.shared.user != nil {
                    Section {
                        Button {
                            showLogoutConfirm = true
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                .foregroundStyle(.red)
                        }
                        .confirmationDialog("Sign Out", isPresented: $showLogoutConfirm) {
                            Button("Sign Out", role: .destructive) {
                                Task {
                                    try? await Clerk.shared.auth.signOut()
                                    CurrentUserProfile.shared.reset()
                                    InteractionStore.shared.reset()
                                    FeedViewModel.shared.reset()
                                    ViewRecorder.shared.reset()
                                    FeedSnapshotStore.clear()
                                    dismiss()
                                }
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("Are you sure you want to sign out?")
                        }
                    }

                    Section {
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete Account", systemImage: "person.crop.circle.badge.xmark")
                                .foregroundStyle(.red)
                        }
                        .confirmationDialog("Delete Account", isPresented: $showDeleteConfirm) {
                            Button("Delete Account", role: .destructive) {
                                Task { await performDeleteAccount() }
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text(
                                "This will permanently delete your account, all projects, and all associated data. This action cannot be undone."
                            )
                        }
                    } footer: {
                        Text("Permanently deletes your account and all associated data. This cannot be undone.")
                    }
                }
            }
            .tint(.brand)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SheetCloseButton { dismiss() }
                }
            }
            .alert(
                "Deletion Failed",
                isPresented: .init(
                    get: { deleteError != nil },
                    set: { if !$0 { deleteError = nil } }
                )
            ) {
                Button("OK") { deleteError = nil }
            } message: {
                Text(deleteError ?? "")
            }
            .overlay {
                if isDeleting {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView()
                                .controlSize(.large)
                            Text("Deleting account…")
                                .font(.headline)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func performDeleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await UserService.shared.deleteAccount()
            try? await Clerk.shared.auth.signOut()
            CurrentUserProfile.shared.reset()
            InteractionStore.shared.reset()
            FeedViewModel.shared.reset()
            ViewRecorder.shared.reset()
            FeedSnapshotStore.clear()
            dismiss()
        } catch {
            deleteError = error.localizedDescription
        }
    }
}

// MARK: - Notification Settings

struct NotificationSettingsView: View {
    @State private var likesEnabled = true
    @State private var commentsEnabled = true
    @State private var followsEnabled = true

    var body: some View {
        List {
            Section {
                Toggle("Likes", isOn: $likesEnabled)
                Toggle("Comments", isOn: $commentsEnabled)
                Toggle("New Followers", isOn: $followsEnabled)
            } header: {
                Label("Push Notifications", systemImage: "bell.badge")
            }
        }
        .tint(.brand)
        .navigationTitle("Notifications")
    }
}

// MARK: - Privacy Settings

struct PrivacySettingsView: View {
    @State private var privateAccount = false

    var body: some View {
        List {
            Section {
                Toggle("Private Account", isOn: $privateAccount)
            } header: {
                Label("Account Visibility", systemImage: "eye")
            } footer: {
                Text("When enabled, only approved followers can see your projects.")
            }
        }
        .tint(.brand)
        .navigationTitle("Privacy")
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        List {
            Section {
                LabeledContent("Version") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                }

                LabeledContent("Build") {
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                }
            } header: {
                Label("App Info", systemImage: "app.badge")
            }

            Section {
                Text(
                    "Demoly is a platform for discovering and sharing creative frontend projects. Built with SwiftUI and Cloudflare Workers."
                )
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("About")
    }
}

#Preview {
    SettingsView()
        .environment(AppearanceSettings.shared)
}
