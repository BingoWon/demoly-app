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
        MainTabView()
    }
}

#Preview {
    RootView()
        .environment(AuthManager())
        .preferredColorScheme(.dark)
}
