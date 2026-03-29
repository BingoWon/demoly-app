//
//  ProjectAccessory.swift
//  Demoly
//
//  Floating accessories with Liquid Glass (iOS 26) / Material (iOS 18)
//

import SwiftUI

// MARK: - Floating Project Accessory

struct FloatingProjectAccessory: View {
    @Binding var showDetail: Bool
    var onLike: (() -> Void)?
    var onComment: (() -> Void)?
    var onCollect: (() -> Void)?
    var onShare: (() -> Void)?

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassProjectAccessory(showDetail: $showDetail, onLike: onLike, onComment: onComment, onCollect: onCollect, onShare: onShare)
        } else {
            ProjectAccessoryContent(showDetail: $showDetail, onLike: onLike, onComment: onComment, onCollect: onCollect, onShare: onShare)
                .frame(height: 48)
                .glassBackground()
                .padding(.horizontal, 20)
        }
    }
}

@available(iOS 26.0, *)
private struct GlassProjectAccessory: View {
    @Binding var showDetail: Bool
    var onLike: (() -> Void)?
    var onComment: (() -> Void)?
    var onCollect: (() -> Void)?
    var onShare: (() -> Void)?
    @Namespace private var ns

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            ProjectAccessoryContent(showDetail: $showDetail, onLike: onLike, onComment: onComment, onCollect: onCollect, onShare: onShare)
                .frame(height: 48)
                .glassEffect(.regular.interactive(), in: .capsule)
                .glassEffectID("projectAccessory", in: ns)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Floating Create Accessory

struct FloatingCreateAccessory: View {
    @Binding var selectedSubTab: CreateSubTab

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassCreateAccessory(selectedSubTab: $selectedSubTab)
        } else {
            CreateTabContent(selectedSubTab: $selectedSubTab)
                .frame(height: 48)
                .glassBackground()
                .padding(.horizontal, 20)
        }
    }
}

@available(iOS 26.0, *)
private struct GlassCreateAccessory: View {
    @Binding var selectedSubTab: CreateSubTab
    @Namespace private var ns

    var body: some View {
        GlassEffectContainer(spacing: 4) {
            CreateTabContent(selectedSubTab: $selectedSubTab)
                .frame(height: 48)
                .glassEffect(.regular.interactive(), in: .capsule)
                .glassEffectID("createAccessory", in: ns)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Shared Content Views

private struct ProjectAccessoryContent: View {
    @Binding var showDetail: Bool
    var onLike: (() -> Void)?
    var onComment: (() -> Void)?
    var onCollect: (() -> Void)?
    var onShare: (() -> Void)?

    private let feed = FeedViewModel.shared
    private var currentProject: Project? { feed.currentProject }
    private var creator: Profile? { currentProject?.creator }

    private let store = InteractionStore.shared

    var body: some View {
        HStack(spacing: 0) {
            Button {
                showDetail = true
            } label: {
                projectInfoLabel
            }

            Spacer(minLength: 0)

            Divider().frame(height: 18).overlay(Color.border)

            interactionButtons

            Spacer().frame(width: 4)
        }
        .foregroundStyle(.primary)
    }

    private var projectInfoLabel: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.brand)
                .frame(width: 28, height: 28)
                .overlay {
                    Text(creator?.initial ?? "?")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(currentProject?.displayTitle ?? "Untitled")
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)

                Text("@\(creator?.handle ?? "unknown")")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.leading, 12)
    }

    private var interactionButtons: some View {
        HStack(spacing: 10) {
            Button(action: { onLike?() }) {
                Image(systemName: store.isLiked(currentProject?.id ?? "") ? "heart.fill" : "heart")
                    .symbolEffect(.bounce, value: store.isLiked(currentProject?.id ?? ""))
            }
            .tint(store.isLiked(currentProject?.id ?? "") ? .red : .primary)

            Button(action: { onComment?() }) {
                Image(systemName: "bubble.right")
            }

            Button(action: { onCollect?() }) {
                Image(systemName: store.isCollected(currentProject?.id ?? "") ? "bookmark.fill" : "bookmark")
                    .symbolEffect(.bounce, value: store.isCollected(currentProject?.id ?? ""))
            }
            .tint(store.isCollected(currentProject?.id ?? "") ? .yellow : .primary)

            if let p = currentProject {
                ProjectShareLink(project: p) {
                    Image(systemName: "square.and.arrow.up")
                        .frame(minWidth: 24)
                }
            } else {
                Button(action: { onShare?() }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
}

private struct CreateTabContent: View {
    @Binding var selectedSubTab: CreateSubTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(CreateSubTab.allCases) { tab in
                Button {
                    withAnimation(.interactive) { selectedSubTab = tab }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .medium))
                        Text(tab.title)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(selectedSubTab == tab ? tab.color : .secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .contentShape(Rectangle())
                }

                if tab != CreateSubTab.allCases.last {
                    Divider().frame(height: 18).overlay(Color.border)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Project Accessory") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
            FloatingProjectAccessory(showDetail: .constant(false))
        }
    }
}

#Preview("Create Accessory") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
            FloatingCreateAccessory(selectedSubTab: .constant(.chat))
        }
    }
}
