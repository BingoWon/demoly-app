//
//  ShareSheet.swift
//  Swipop
//

import SwiftUI

struct ProjectShareLink<Label: View>: View {
    let project: Project
    @ViewBuilder let label: Label

    private var shareURL: URL {
        URL(string: "https://swipop.app/project/\(project.id)")!
    }

    var body: some View {
        ShareLink(
            item: shareURL,
            subject: Text(project.displayTitle),
            message: Text("\(project.displayTitle) on Swipop")
        ) {
            label
        }
    }
}

extension ProjectShareLink where Label == SwiftUI.Label<Text, Image> {
    init(project: Project) {
        self.project = project
        self.label = Label("Share", systemImage: "square.and.arrow.up")
    }
}
