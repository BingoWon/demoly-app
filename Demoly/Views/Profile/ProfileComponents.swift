//
//  ProfileComponents.swift
//  Demoly
//
//  Shared UI components for profile views
//

import SwiftUI

// MARK: - Compact Profile Header (Modern Design)

struct ProfileHeaderView: View {
    let profile: Profile?
    var isLoading = false
    var showEditButton = false
    var onEditTapped: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                avatarImage
                    .redacted(reason: isLoading ? .placeholder : [])

                // Name + Handle
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile?.name ?? "User")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text("@\(profile?.handle ?? "user")")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .redacted(reason: isLoading ? .placeholder : [])

                Spacer()

                // Edit button (optional)
                if showEditButton {
                    Button {
                        onEditTapped?()
                    } label: {
                        Text("Edit")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.secondaryBackground)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            // Bio
            if let bio = profile?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(3)
            }

            // Links
            if let links = profile?.links, !links.isEmpty {
                linksView(links)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var avatarImage: some View {
        if let url = profile?.resolvedAvatarURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image.resizable().scaledToFill()
                default:
                    avatarFallback
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(Circle())
        } else {
            avatarFallback
        }
    }

    private var avatarFallback: some View {
        Circle()
            .fill(Color.brand)
            .frame(width: 72, height: 72)
            .overlay(
                Text(profile?.initial ?? "U")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            )
    }

    private func linksView(_ links: [ProfileLink]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(links) { link in
                    LinkChip(link: link)
                }
            }
        }
    }
}

// MARK: - Link Chip

private struct LinkChip: View {
    let link: ProfileLink

    var body: some View {
        Link(destination: URL(string: link.url) ?? URL(string: "https://appleragmcp.com")!) {
            HStack(spacing: 6) {
                Image(systemName: "link")
                    .font(.system(size: 12))
                Text(link.title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(Color.brand)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.brand.opacity(0.1))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Compact Stats Row

struct ProfileStatsRow: View {
    let projectCount: Int
    let followerCount: Int
    let followingCount: Int
    var isLoading = false

    var body: some View {
        HStack(spacing: 0) {
            statItem(value: projectCount, label: "Projects")

            Divider()
                .frame(height: 24)
                .overlay(Color.border)

            statItem(value: followerCount, label: "Followers")

            Divider()
                .frame(height: 24)
                .overlay(Color.border)

            statItem(value: followingCount, label: "Following")
        }
        .padding(.vertical, 12)
        .background(Color.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .redacted(reason: isLoading ? .placeholder : [])
    }

    private func statItem(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value.formatted)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
