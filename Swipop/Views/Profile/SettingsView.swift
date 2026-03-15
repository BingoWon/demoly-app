//
//  SettingsView.swift
//  Swipop
//

import ClerkKit
import ClerkKitUI
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppearanceSettings.self) private var appearance
    @State private var showLogoutConfirm = false

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
                                Text({
                                    let name = [user.firstName, user.lastName]
                                        .compactMap { $0 }
                                        .joined(separator: " ")
                                    return name.isEmpty ? "User" : name
                                }())
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
                        .listRowBackground(Color.tertiaryBackground.opacity(0.8))
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
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))
                } header: {
                    Label("Appearance", systemImage: "paintbrush.pointed")
                }

                Section {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))

                    NavigationLink {
                        PrivacySettingsView()
                    } label: {
                        Label("Privacy", systemImage: "lock")
                    }
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))
                } header: {
                    Label("Preferences", systemImage: "slider.horizontal.3")
                }

                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About Swipop", systemImage: "info.circle")
                    }
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))

                    Link(destination: URL(string: "https://swipop.app/terms")!) {
                        HStack {
                            Label("Terms of Service", systemImage: "doc.text")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))

                    Link(destination: URL(string: "https://swipop.app/privacy")!) {
                        HStack {
                            Label("Privacy Policy", systemImage: "hand.raised")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))
                } header: {
                    Label("About", systemImage: "info.circle")
                }

                Section {
                    Button {
                        showLogoutConfirm = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.red)
                    }
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))
                }
            }
            .tint(.brand)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SheetCloseButton { dismiss() }
                }
            }
            .confirmationDialog("Sign Out", isPresented: $showLogoutConfirm) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await Clerk.shared.auth.signOut()
                        CurrentUserProfile.shared.reset()
                        InteractionStore.shared.reset()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .glassSheetBackground()
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
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))
                Toggle("Comments", isOn: $commentsEnabled)
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))
                Toggle("New Followers", isOn: $followsEnabled)
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))
            } header: {
                Label("Push Notifications", systemImage: "bell.badge")
            }
        }
        .tint(.brand)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
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
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))
            } header: {
                Label("Account Visibility", systemImage: "eye")
            } footer: {
                Text("When enabled, only approved followers can see your projects.")
            }
        }
        .tint(.brand)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Privacy")
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.tertiaryBackground.opacity(0.8))

                HStack {
                    Text("Build")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.tertiaryBackground.opacity(0.8))
            } header: {
                Label("App Info", systemImage: "app.badge")
            }

            Section {
                Text("Swipop is a platform for discovering and sharing creative frontend projects. Built with SwiftUI and Cloudflare Workers.")
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.tertiaryBackground.opacity(0.8))
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("About")
    }
}

#Preview {
    SettingsView()
        .environment(AppearanceSettings.shared)
}
