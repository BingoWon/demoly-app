//
//  AuthManager.swift
//  Demoly
//

import ClerkKit
import ClerkKitUI
import SwiftUI
import Observation

@MainActor
@Observable
final class AuthManager {
    var showAuthSheet = false

    func requireLogin(action: @escaping () -> Void) {
        if Clerk.shared.user != nil {
            action()
        } else {
            showAuthSheet = true
        }
    }
}

struct AuthContainerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AuthView()
            .onChange(of: Clerk.shared.user?.id) { _, newId in
                if newId != nil {
                    dismiss()
                }
            }
    }
}
