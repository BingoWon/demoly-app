//
//  MasonryGrid.swift
//  Demoly
//
//  Adaptive column-based grid layout. Column count auto-scales with available
//  width, mirroring the web frontend's CSS `columns-[220px]` behavior. The
//  greedy shortest-column algorithm is retained for variable-height support.
//

import SwiftUI

// MARK: - Grid Metrics

/// Computes adaptive column count and width from available space.
enum GridMetrics {
    /// Compute optimal column layout for given constraints.
    ///
    /// The formula accounts for `MasonryGrid`'s `padding(.horizontal, spacing)`
    /// plus inter-column gaps: `width = columns × columnWidth + (columns+1) × spacing`.
    static func compute(
        width: CGFloat,
        minColumnWidth: CGFloat,
        spacing: CGFloat
    ) -> (columns: Int, columnWidth: CGFloat) {
        guard width > 0, minColumnWidth > 0 else { return (1, max(width, 1)) }
        let n = max(Int((width - spacing) / (minColumnWidth + spacing)), 1)
        let cw = max((width - CGFloat(n + 1) * spacing) / CGFloat(n), 1)
        return (n, cw)
    }
}

// MARK: - MasonryGrid

struct MasonryGrid<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let columns: Int
    let spacing: CGFloat
    let content: (Item) -> Content
    let heightProvider: (Item) -> CGFloat

    init(
        items: [Item],
        columns: Int = 2,
        spacing: CGFloat = 4,
        @ViewBuilder content: @escaping (Item) -> Content,
        heightProvider: @escaping (Item) -> CGFloat
    ) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.content = content
        self.heightProvider = heightProvider
    }

    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columns, id: \.self) { columnIndex in
                LazyVStack(spacing: spacing) {
                    ForEach(itemsForColumn(columnIndex)) { item in
                        content(item)
                    }
                }
            }
        }
        .padding(.horizontal, spacing)
    }

    /// Distribute items to columns based on cumulative height (greedy algorithm)
    private func itemsForColumn(_ column: Int) -> [Item] {
        var columnHeights = Array(repeating: CGFloat.zero, count: columns)
        var columnItems: [[Item]] = Array(repeating: [], count: columns)

        for item in items {
            let shortestColumn = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            columnItems[shortestColumn].append(item)
            columnHeights[shortestColumn] += heightProvider(item) + spacing
        }

        return columnItems[column]
    }
}

// MARK: - Project convenience initializer

extension MasonryGrid where Item == Project {
    /// Adaptive project grid — pass pre-computed `columns` and `columnWidth`
    /// from `GridMetrics.compute(width:minColumnWidth:spacing:)`.
    ///
    /// - Parameter infoHeight: Extra height below thumbnail (e.g. 60 for
    ///   title + creator row, 0 for thumbnail-only grids).
    init(
        projects: [Project],
        columns: Int,
        columnWidth: CGFloat,
        infoHeight: CGFloat = 0,
        spacing: CGFloat = 4,
        @ViewBuilder content: @escaping (Project) -> Content
    ) {
        self.init(
            items: projects,
            columns: columns,
            spacing: spacing,
            content: content,
            heightProvider: { _ in
                columnWidth / Thumbnail.aspectRatio + infoHeight
            }
        )
    }
}
