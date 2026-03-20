//
//  AuthManager.swift
//  Demoly
//

import ClerkKit
import Observation

@MainActor
@Observable
final class AuthManager {
    var showAuthSheet = false

    func requireLogin(action: () -> Void) {
        if Clerk.shared.user != nil {
            action()
        } else {
            showAuthSheet = true
        }
    }
}
