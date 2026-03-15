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

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    avatarView
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                Section("Profile") {
                    fieldRow(label: "Display Name") {
                        TextField("Your name", text: $displayName)
                            .focused($focusedField, equals: .displayName)
                    }

                    fieldRow(label: "Username") {
                        TextField("username", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .username)
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
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .fontWeight(.semibold)
                    .disabled(isSaving)
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
                    } else {
                        Circle()
                            .fill(Color.brand)
                            .frame(width: 72, height: 72)
                            .overlay(
                                Text((displayName.isEmpty ? "U" : displayName).prefix(1).uppercased())
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(.white)
                            )
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

    // MARK: - Save

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let filteredLinks = links.filter { !$0.title.isEmpty && !$0.url.isEmpty }

        do {
            _ = try await userService.updateProfile(ProfileUpdatePayload(
                username: username.isEmpty ? nil : username,
                displayName: displayName.isEmpty ? nil : displayName,
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
