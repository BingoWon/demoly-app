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
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text(message)
                .font(.title3)
                .foregroundStyle(.primary)
            
            Button {
                authManager.showAuthSheet = true
            } label: {
                Text("Sign In")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.brand)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SignInPromptView(icon: "person.circle", message: "Sign in to see your profile")
        .environment(AuthManager())
}
