//
//  ProjectShareLink.swift
//  Demoly
//

import SwiftUI

struct ProjectShareLink<Label: View>: View {
    let project: Project
    @ViewBuilder let label: Label

    private var shareURL: URL {
        URL(string: "https://demoly.thebinwang.com/project/\(project.id)")!
    }

    var body: some View {
        ShareLink(
            item: shareURL,
            subject: Text(project.displayTitle),
            message: Text("\(project.displayTitle) on Demoly")
        ) {
            label
        }
    }
}

extension ProjectShareLink where Label == SwiftUI.Label<Text, Image> {
    init(project: Project) {
        self.project = project
        label = Label("Share", systemImage: "square.and.arrow.up")
    }
}
