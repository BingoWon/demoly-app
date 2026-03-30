//
//  GridMetrics.swift
//  Demoly
//
//  Adaptive column-based grid layout metrics. Column count auto-scales with
//  available width using the same algorithm as the web frontend's CSS Grid.
//

import SwiftUI

enum GridMetrics {
    /// Minimum column width for the feed (Discover) grid.
    static let feedMinColumnWidth: CGFloat = 170
    static let feedSpacing: CGFloat = 4

    /// Grid cell aspect ratio (9:19) — compact enough to show more items per screen.
    static let previewAspectRatio: CGFloat = 9.0 / 19.0

    /// Compute optimal column layout for given constraints.
    ///
    /// The formula accounts for horizontal padding plus inter-column gaps:
    /// `width = columns × columnWidth + (columns+1) × spacing`.
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

    /// Build LazyVGrid columns array from computed layout.
    static func gridItems(columns: Int, spacing: CGFloat) -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
    }
}
