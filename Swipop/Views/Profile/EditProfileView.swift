//
//  EditProfileView.swift
//  Swipop
//

import PhotosUI
import SwiftUI

struct EditProfileView: View {
    let profile: Profile?

    @Environment(\.dismiss) private var dismiss
    @State private var username: String
    @State private var displayName: String
    @State private var bio: String
    @State private var links: [ProfileLink]
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @FocusState private var focusedField: Field?

    private enum Field { case displayName, username, bio }

    private let userService = UserService.shared

    init(profile: Profile?) {
        self.profile = profile
        _username = State(initialValue: profile?.username ?? "")
        _displayName = State(initialValue: profile?.displayName ?? "")
        _bio = State(initialValue: profile?.bio ?? "")
        _links = State(initialValue: profile?.links ?? [])
    }

    private var displayNameError: String? {
        displayName.trimmingCharacters(in: .whitespaces).isEmpty ? "Display name is required" : nil
    }

    private var usernameError: String? {
        username.trimmingCharacters(in: .whitespaces).isEmpty ? "Username is required" : nil
    }

    private var canSave: Bool {
        !isSaving && displayNameError == nil && usernameError == nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    avatarView
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                Section("Profile") {
                    VStack(alignment: .leading, spacing: 4) {
                        fieldRow(label: "Display Name") {
                            TextField("Your name", text: $displayName)
                                .focused($focusedField, equals: .displayName)
                        }
                        if let error = displayNameError {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundStyle(.red)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        fieldRow(label: "Username") {
                            TextField("username", text: $username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .username)
                        }
                        if let error = usernameError {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundStyle(.red)
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bio")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)

                        TextEditor(text: $bio)
                            .font(.system(size: 16))
                            .frame(minHeight: 60)
                            .scrollContentBackground(.hidden)
                            .focused($focusedField, equals: .bio)
                    }
                }

                Section {
                    ForEach($links) { $link in
                        LinkEditRow(link: $link, onDelete: {
                            links.removeAll { $0.id == link.id }
                        })
                    }

                    Button {
                        links.append(ProfileLink())
                    } label: {
                        Label("Add Link", systemImage: "plus.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.brand)
                    }
                } header: {
                    Text("Links")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }

                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") { focusedField = nil }
                    }
                }
            }
            .alert("Error", isPresented: .init(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveError ?? "")
            }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data)
                    {
                        avatarImage = image
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Field Row

    private func fieldRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)

            content()
                .font(.system(size: 16))
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Avatar View

    private var avatarView: some View {
        HStack {
            Spacer()
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack {
                    if let avatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(Circle())
                    } else if let url = profile?.resolvedAvatarURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
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

                    Circle()
                        .fill(.black.opacity(0.35))
                        .frame(width: 72, height: 72)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .foregroundStyle(.white)
                                .font(.system(size: 16))
                        )
                }
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    private var avatarFallback: some View {
        Circle()
            .fill(Color.brand)
            .frame(width: 72, height: 72)
            .overlay(
                Text((displayName.isEmpty ? "U" : displayName).prefix(1).uppercased())
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            )
    }

    // MARK: - Save

    private func save() async {
        guard canSave else { return }
        isSaving = true
        defer { isSaving = false }

        let filteredLinks = links.filter { !$0.title.isEmpty && !$0.url.isEmpty }

        do {
            if let image = avatarImage {
                _ = try await userService.uploadAvatar(image: image)
            }

            _ = try await userService.updateProfile(ProfileUpdatePayload(
                username: username.trimmingCharacters(in: .whitespaces),
                displayName: displayName.trimmingCharacters(in: .whitespaces),
                bio: bio.isEmpty ? nil : bio,
                links: filteredLinks.isEmpty ? nil : filteredLinks
            ))
            await CurrentUserProfile.shared.refresh()
            dismiss()
        } catch {
            if error.localizedDescription.lowercased().contains("unique") ||
                error.localizedDescription.lowercased().contains("username")
            {
                saveError = "This username is already taken."
            } else {
                saveError = error.localizedDescription
            }
        }
    }
}

// MARK: - Link Edit Row

private struct LinkEditRow: View {
    @Binding var link: ProfileLink
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Title")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .leading)

                TextField("e.g. GitHub", text: $link.title)
                    .font(.system(size: 16))

                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }

            HStack {
                Text("URL")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .leading)

                TextField("https://", text: $link.url)
                    .font(.system(size: 16))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
            }
        }
    }
}

#Preview {
    EditProfileView(profile: .sample)
}
