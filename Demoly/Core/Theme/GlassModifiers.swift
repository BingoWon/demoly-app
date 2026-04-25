//
//  GlassModifiers.swift
//  Demoly
//
//  Unified glass effect: Liquid Glass (iOS 26) / Material (iOS 18)
//

import SwiftUI

// MARK: - Glass Background Modifier

struct GlassBackgroundModifier: ViewModifier {
    var shape: GlassShape = .capsule

    enum GlassShape {
        case capsule
        case roundedRect(cornerRadius: CGFloat)
    }

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            switch shape {
            case .capsule:
                content.glassEffect(.regular.interactive(), in: .capsule)
            case let .roundedRect(radius):
                content.glassEffect(.regular.interactive(), in: .rect(cornerRadius: radius))
            }
        } else {
            switch shape {
            case .capsule:
                materialFallback(content, shape: Capsule())
            case let .roundedRect(radius):
                materialFallback(content, shape: RoundedRectangle(cornerRadius: radius))
            }
        }
    }

    private func materialFallback(_ content: Content, shape: some InsettableShape) -> some View {
        content
            .background(shape.fill(.ultraThinMaterial))
            .overlay(shape.strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Sheet Close Button

struct SheetCloseButton: View {
    let action: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            Button(role: .close, action: action)
        } else {
            Button(action: action) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    func glassBackground(shape: GlassBackgroundModifier.GlassShape = .capsule) -> some View {
        modifier(GlassBackgroundModifier(shape: shape))
    }
}
