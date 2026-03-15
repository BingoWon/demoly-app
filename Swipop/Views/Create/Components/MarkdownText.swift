//
//  MarkdownText.swift
//  Swipop
//
//  Renders Markdown content with proper styling for chat messages
//

import SwiftUI

struct MarkdownText: View {
    let content: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if content.isEmpty {
            Text("...")
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(parseBlocks(content).enumerated()), id: \.offset) { _, block in
                    renderBlock(block)
                }
            }
        }
    }

    // MARK: - Block Rendering

    @ViewBuilder
    private func renderBlock(_ block: MarkdownBlock) -> some View {
        switch block {
        case let .heading(level, text):
            Text(inlineMarkdown(text))
                .font(.system(size: headingSize(level), weight: .bold))
                .foregroundStyle(.primary)
                .padding(.top, level == 1 ? 4 : 2)

        case let .listItem(text, ordered, index):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(ordered ? "\(index)." : "•")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 18, alignment: .trailing)
                Text(inlineMarkdown(text))
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
            }

        case let .paragraph(text):
            Text(inlineMarkdown(text))
                .font(.system(size: 15))
                .foregroundStyle(.primary)
                .textSelection(.enabled)

        case let .blockquote(text):
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.brand.opacity(0.5))
                    .frame(width: 3)
                Text(inlineMarkdown(text))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
        }
    }

    private func headingSize(_ level: Int) -> CGFloat {
        switch level {
        case 1: 20
        case 2: 18
        case 3: 16
        default: 15
        }
    }

    // MARK: - Inline Markdown → AttributedString

    private func inlineMarkdown(_ text: String) -> AttributedString {
        do {
            var attributed = try AttributedString(markdown: text, options: .init(
                allowsExtendedAttributes: true,
                interpretedSyntax: .inlineOnlyPreservingWhitespace,
                failurePolicy: .returnPartiallyParsedIfPossible
            ))

            attributed.foregroundColor = colorScheme == .dark ? .white : .black

            for run in attributed.runs {
                if run.inlinePresentationIntent?.contains(.code) == true {
                    let range = run.range
                    attributed[range].font = .system(size: 14, design: .monospaced)
                    attributed[range].backgroundColor = colorScheme == .dark
                        ? Color.white.opacity(0.1)
                        : Color.black.opacity(0.1)
                }
            }

            return attributed
        } catch {
            var plain = AttributedString(text)
            plain.foregroundColor = colorScheme == .dark ? .white : .black
            plain.font = .system(size: 15)
            return plain
        }
    }

    // MARK: - Block-Level Parsing

    private enum MarkdownBlock {
        case heading(level: Int, text: String)
        case listItem(text: String, ordered: Bool, index: Int)
        case paragraph(String)
        case blockquote(String)
    }

    private func parseBlocks(_ content: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var orderedIndex = 0
        var paragraph = ""

        func flushParagraph() {
            let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                blocks.append(.paragraph(trimmed))
            }
            paragraph = ""
        }

        for line in content.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                flushParagraph()
                orderedIndex = 0
                continue
            }

            if let match = trimmed.wholeMatch(of: /^(#{1,4})\s+(.+)/) {
                flushParagraph()
                let level = match.1.count
                blocks.append(.heading(level: level, text: String(match.2)))
                orderedIndex = 0
            } else if let match = trimmed.wholeMatch(of: /^[-*+]\s+(.+)/) {
                flushParagraph()
                blocks.append(.listItem(text: String(match.1), ordered: false, index: 0))
                orderedIndex = 0
            } else if let match = trimmed.wholeMatch(of: /^(\d+)[.)]\s+(.+)/) {
                flushParagraph()
                orderedIndex += 1
                let displayIndex = Int(match.1) ?? orderedIndex
                blocks.append(.listItem(text: String(match.2), ordered: true, index: displayIndex))
            } else if let match = trimmed.wholeMatch(of: /^>\s*(.*)/) {
                flushParagraph()
                blocks.append(.blockquote(String(match.1)))
                orderedIndex = 0
            } else {
                if paragraph.isEmpty {
                    paragraph = trimmed
                } else {
                    paragraph += "\n" + trimmed
                }
            }
        }

        flushParagraph()

        if blocks.isEmpty {
            blocks.append(.paragraph(content))
        }

        return blocks
    }
}

// MARK: - Code Block View

struct CodeBlockView: View {
    let code: String
    let language: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let language, !language.isEmpty {
                HStack {
                    Text(language.uppercased())
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = code
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.secondaryBackground.opacity(0.5))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.primary.opacity(0.9))
                    .textSelection(.enabled)
                    .padding(12)
            }
        }
        .background(Color.secondaryBackground.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.border, lineWidth: 1)
        )
    }
}

// MARK: - Rich Message Content

struct RichMessageContent: View {
    let content: String

    var body: some View {
        let blocks = parseContentBlocks(content)

        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case let .text(text):
                    MarkdownText(content: text)
                case let .code(code, language):
                    CodeBlockView(code: code, language: language)
                }
            }
        }
    }

    // MARK: - Parsing

    private enum ContentBlock {
        case text(String)
        case code(String, language: String?)
    }

    private func parseContentBlocks(_ content: String) -> [ContentBlock] {
        var blocks: [ContentBlock] = []
        let remaining = content

        let codeBlockPattern = #"```(\w*)\n?([\s\S]*?)```"#

        guard let regex = try? NSRegularExpression(pattern: codeBlockPattern) else {
            return [.text(content)]
        }

        var lastEnd = 0
        let nsString = remaining as NSString

        regex.enumerateMatches(in: remaining, range: NSRange(location: 0, length: nsString.length)) { match, _, _ in
            guard let match else { return }

            if match.range.location > lastEnd {
                let textRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                let text = nsString.substring(with: textRange).trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    blocks.append(.text(text))
                }
            }

            let language = match.range(at: 1).location != NSNotFound
                ? nsString.substring(with: match.range(at: 1))
                : nil
            let code = match.range(at: 2).location != NSNotFound
                ? nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
                : ""

            if !code.isEmpty {
                blocks.append(.code(code, language: language?.isEmpty == true ? nil : language))
            }

            lastEnd = match.range.location + match.range.length
        }

        if lastEnd < nsString.length {
            let text = nsString.substring(from: lastEnd).trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                blocks.append(.text(text))
            }
        }

        if blocks.isEmpty {
            blocks.append(.text(content))
        }

        return blocks
    }
}
