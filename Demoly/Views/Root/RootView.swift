//
//  RootView.swift
//  Demoly
//
//  Root view - users can browse without login
//

import ClerkKit
import ClerkKitUI
import SwiftUI

struct RootView: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        @Bindable var authManager = authManager
        MainTabView()
            .sheet(isPresented: $authManager.showAuthSheet) {
                AuthView()
            }
            .onChange(of: Clerk.shared.user?.id) { _, newId in
                if newId != nil { authManager.showAuthSheet = false }
            }
    }
}

#Preview {
    RootView()
        .environment(AuthManager())
        .preferredColorScheme(.dark)
}
