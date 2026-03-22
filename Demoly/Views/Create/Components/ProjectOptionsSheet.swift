//
//  ProjectOptionsSheet.swift
//  Demoly
//
//  Sheet for editing project metadata and visibility
//

import SwiftUI

struct ProjectOptionsSheet: View {
    @Bindable var projectEditor: ProjectEditorViewModel
    @Bindable var chatViewModel: ChatViewModel
    var onDelete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var tagInput = ""
    @State private var showDeleteConfirmation = false
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            formContent
                .navigationTitle("Project Options")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task {
                                isSaving = true
                                await projectEditor.save()
                                isSaving = false
                                dismiss()
                            }
                        } label: {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("Save")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.brand)
                            }
                        }
                        .disabled(isSaving)
                    }
                }
                .alert(
                    "Delete this project?",
                    isPresented: $showDeleteConfirmation
                ) {
                    Button("Delete", role: .destructive) {
                        dismiss()
                        onDelete?()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will permanently delete your project, including all code and chat history. This action cannot be undone.")
                }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Form Content

    private var formContent: some View {
        Form {
            detailsSection
            tagsSection
            visibilitySection
            modelSection
            contextSection
            dangerSection
        }
    }

    private var detailsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("Title")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                TextField("Enter title", text: $projectEditor.title)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Description")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                TextField("Enter description", text: $projectEditor.description, axis: .vertical)
                    .font(.system(size: 16))
                    .lineLimit(3...6)
            }
        } header: {
            Label("Details", systemImage: "doc.text")
        }
    }

    private var tagsSection: some View {
        Section {
            tagsEditor
        } header: {
            Label("Tags", systemImage: "tag")
        }
    }

    private var visibilitySection: some View {
        Section {
            visibilityPicker
        } header: {
            Label("Visibility", systemImage: "eye")
        }
    }

    private var modelSection: some View {
        Section {
            modelPicker
        } header: {
            Label("AI Model", systemImage: "cpu")
        }
    }

    private var contextSection: some View {
        Section {
            contextWindowView
        } header: {
            Label("Context", systemImage: "brain")
        } footer: {
            Text(
                "Auto-summarize is always enabled. When context reaches capacity, conversation will be automatically compacted to continue."
            )
            .font(.system(size: 12))
        }
    }

    @ViewBuilder
    private var dangerSection: some View {
        if projectEditor.projectId != nil {
            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Project")
                    }
                }
            }
        }
    }

    // MARK: - AI Model Picker

    private var modelPicker: some View {
        Picker("Model", selection: $chatViewModel.selectedModel) {
            ForEach(AIModel.allCases) { model in
                Text(model.displayName).tag(model)
            }
        }
        .pickerStyle(.menu)
    }

    // MARK: - Context Window

    private var contextWindowView: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                let usedWidth = geo.size.width * min(chatViewModel.usagePercentage, 1.0)
                let bufferStart = geo.size.width * (Double(ChatViewModel.usableLimit) / Double(ChatViewModel.contextLimit))

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondaryBackground)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondaryBackground.opacity(0.5))
                        .frame(width: geo.size.width - bufferStart)
                        .offset(x: bufferStart)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(contextColor(for: chatViewModel.usagePercentage))
                        .frame(width: max(usedWidth, 0))
                }
            }
            .frame(height: 8)

            HStack(spacing: 0) {
                statItem(
                    label: "Used",
                    value: formatTokens(chatViewModel.promptTokens),
                    color: contextColor(for: chatViewModel.usagePercentage)
                )

                Divider()
                    .frame(height: 28)
                    .background(Color.border)

                statItem(
                    label: "Available",
                    value: formatTokens(ChatViewModel.usableLimit - chatViewModel.promptTokens),
                    color: .primary
                )

                Divider()
                    .frame(height: 28)
                    .background(Color.border)

                statItem(
                    label: "Buffer",
                    value: formatTokens(ChatViewModel.bufferSize),
                    color: .secondary
                )

                Divider()
                    .frame(height: 28)
                    .background(Color.border)

                statItem(
                    label: "Total",
                    value: "128K",
                    color: .secondary
                )
            }
        }
        .padding(.vertical, 4)
    }

    private func statItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func contextColor(for percentage: Double) -> Color {
        if percentage >= 0.8 { return .red }
        if percentage >= 0.6 { return .orange }
        return .green
    }

    private func formatTokens(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.0fK", Double(count) / 1000)
        }
        return "\(count)"
    }

    // MARK: - Visibility

    private var visibilityPicker: some View {
        Toggle(isOn: $projectEditor.isPublished) {
            VStack(alignment: .leading, spacing: 4) {
                Text(projectEditor.isPublished ? "Published" : "Draft")
                    .font(.system(size: 16, weight: .medium))
                Text(projectEditor.isPublished ? "Everyone can see this project" : "Only you can see this project")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.green)
    }

    // MARK: - Tags

    private var tagsEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Add tag...", text: $tagInput)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit(addTag)

                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(tagInput.isEmpty ? Color.secondary : Color.brand)
                }
                .disabled(tagInput.isEmpty)
            }

            if !projectEditor.tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(projectEditor.tags, id: \.self) { tag in
                        TagChip(tag: tag) {
                            projectEditor.tags.removeAll { $0 == tag }
                        }
                    }
                }
            }
        }
    }

    private func addTag() {
        let tag = tagInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !tag.isEmpty, !projectEditor.tags.contains(tag) else { return }
        projectEditor.tags.append(tag)
        tagInput = ""
    }
}

// MARK: - Tag Chip

private struct TagChip: View {
    let tag: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.system(size: 13, weight: .medium))
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.brand.opacity(0.3))
        .clipShape(Capsule())
    }
}

#Preview {
    @Previewable @State var projectEditor = ProjectEditorViewModel()
    ProjectOptionsSheet(projectEditor: projectEditor, chatViewModel: ChatViewModel(projectEditor: projectEditor)) {
        print("Delete tapped")
    }
}
