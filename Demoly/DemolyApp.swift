//
//  DemolyApp.swift
//  Demoly
//

import ClerkKit
import SwiftUI

@main
struct DemolyApp: App {
    @State private var clerk: Clerk
    @State private var authManager = AuthManager()
    @State private var appearance = AppearanceSettings.shared

    init() {
        let clerk = Clerk.configure(publishableKey: Config.clerkPublishableKey)
        _clerk = State(initialValue: clerk)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if clerk.isLoaded {
                    RootView()
                        .environment(clerk)
                        .environment(authManager)
                        .environment(appearance)
                        .onAppear { appearance.applyToWindow() }
                } else {
                    VStack(spacing: 16) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Loading...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .task { await AIConfig.shared.load() }
            .task(id: clerk.user?.id) {
                guard clerk.isLoaded else { return }
                if clerk.user != nil {
                    await CurrentUserProfile.shared.preload()
                } else {
                    CurrentUserProfile.shared.reset()
                    InteractionStore.shared.reset()
                }
            }
        }
    }
}
