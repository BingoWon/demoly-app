//
//  SignInPromptView.swift
//  Demoly
//

import SwiftUI

struct SignInPromptView: View {
    @Environment(AuthManager.self) private var authManager

    let icon: String
    let message: String

    var body: some View {
        ActionPromptView(
            icon: icon,
            message: message,
            buttonTitle: "Sign In"
        ) {
            authManager.showAuthSheet = true
        }
    }
}

#Preview {
    SignInPromptView(icon: "person.circle", message: "Sign in to see your profile")
        .environment(AuthManager())
}
