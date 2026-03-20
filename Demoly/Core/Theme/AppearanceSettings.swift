//
//  AppearanceSettings.swift
//  Demoly
//
//  App appearance/theme management
//

import SwiftUI
import UIKit

/// App appearance mode
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }

    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
    }
}

/// Global appearance settings — uses UIKit window override to bypass SwiftUI sheet bugs
@MainActor
@Observable
final class AppearanceSettings {
    static let shared = AppearanceSettings()

    var mode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: "appearanceMode")
            applyToWindow()
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "appearanceMode") ?? "system"
        mode = AppearanceMode(rawValue: saved) ?? .system
    }

    func applyToWindow() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        for window in windowScene.windows {
            window.overrideUserInterfaceStyle = mode.interfaceStyle
        }
    }
}
