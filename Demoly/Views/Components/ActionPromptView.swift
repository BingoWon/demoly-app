//
//  ActionPromptView.swift
//  Demoly
//

import SwiftUI

struct ActionPromptView: View {
    let icon: String
    var title: String? = nil
    let message: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                if let title {
                    Text(title)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                }

                Text(message)
                    .font(title == nil ? .title3 : .subheadline)
                    .foregroundStyle(title == nil ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                action()
            } label: {
                Text(buttonTitle)
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
    VStack {
        // Without Title (Auth Style)
        ActionPromptView(
            icon: "person.circle",
            message: "Sign in to see your profile",
            buttonTitle: "Sign In",
            action: {}
        )

        Divider()

        // With Title (Network Error Style)
        ActionPromptView(
            icon: "wifi.exclamationmark",
            title: "Connection Error",
            message: "Could not connect to the server.",
            buttonTitle: "Tap to Retry",
            action: {}
        )
    }
}
