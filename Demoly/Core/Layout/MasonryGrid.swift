//
//  MasonryGrid.swift
//  Demoly
//
//  Adaptive column-based grid layout. Column count auto-scales with available
//  width using the same algorithm as the web frontend's CSS Grid. The greedy
//  shortest-column algorithm is retained for variable-height support.
//

import SwiftUI

// MARK: - Grid Metrics

/// Computes adaptive column count and width from available space.
enum GridMetrics {
    /// Minimum column width for the feed (Discover) grid.
    static let feedMinColumnWidth: CGFloat = 170
    static let feedSpacing: CGFloat = 4

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

    /// Column width for a known column count.
    static func columnWidth(width: CGFloat, columns: Int, spacing: CGFloat) -> CGFloat {
        guard columns > 0 else { return max(width, 1) }
        return max((width - CGFloat(columns + 1) * spacing) / CGFloat(columns), 1)
    }

    /// Profile grid: always one more column than the feed at the same width.
    static func profileLayout(width: CGFloat, spacing: CGFloat = 2) -> (columns: Int, columnWidth: CGFloat) {
        let (feedCols, _) = compute(width: width, minColumnWidth: feedMinColumnWidth, spacing: feedSpacing)
        let cols = feedCols + 1
        let cw = columnWidth(width: width, columns: cols, spacing: spacing)
        return (cols, cw)
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
