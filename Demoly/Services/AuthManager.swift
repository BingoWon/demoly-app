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
    var showAuthSheet = false {
        didSet {
            if showAuthSheet {
                presentAuthSheet()
                showAuthSheet = false // Reset immediately since UIKit manages the state
            }
        }
    }

    func requireLogin(action: @escaping () -> Void) {
        if Clerk.shared.user != nil {
            action()
        } else {
            showAuthSheet = true
        }
    }

    func presentAuthSheet() {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0 is UIWindowScene }) as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootVC = window.rootViewController else { return }

        let topmostVC = topMost(of: rootVC)
        
        let container = AuthContainerView()
        let hostingController = UIHostingController(rootView: container
            .environment(Clerk.shared)
            .environment(self)
            .environment(AppearanceSettings.shared)
        )
        hostingController.modalPresentationStyle = .pageSheet
        
        topmostVC.present(hostingController, animated: true)
    }

    private func topMost(of vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController {
            return topMost(of: presented)
        }
        if let nav = vc as? UINavigationController, let visible = nav.visibleViewController {
            return topMost(of: visible)
        }
        if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
            return topMost(of: selected)
        }
        return vc
    }
}

private struct AuthContainerView: View {
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
