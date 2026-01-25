import SwiftUI

// MARK: - Markdown View

struct MarkdownView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(parseBlocks().enumerated()), id: \.offset) { _, block in
                block
            }
        }
    }

    // MARK: - Block-level parsing

    private func parseBlocks() -> [AnyView] {
        var views: [AnyView] = []
        // Normalize line endings and special characters
        let normalizedText = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "`", with: "`")  // Curly backtick to straight
            .replacingOccurrences(of: "´", with: "`")  // Acute accent to backtick
            .replacingOccurrences(of: "'", with: "`")  // Smart quote to backtick (when used as code)
            .replacingOccurrences(of: "＃", with: "#")  // Full-width # to ASCII
            .replacingOccurrences(of: "♯", with: "#")  // Musical sharp to #
        let lines = normalizedText.components(separatedBy: "\n")
        var i = 0

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Fenced code block ```
            if trimmed.hasPrefix("```") {
                let language = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var codeLines: [String] = []
                i += 1

                while i < lines.count {
                    let codeLine = lines[i]
                    if codeLine.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                        i += 1
                        break
                    }
                    codeLines.append(codeLine)
                    i += 1
                }

                let code = codeLines.joined(separator: "\n")
                views.append(AnyView(CodeBlockView(code: code, language: language)))
                continue
            }

            // Headers (with or without space after #)
            if trimmed.hasPrefix("###") {
                var content = String(trimmed.dropFirst(3))
                if content.hasPrefix(" ") { content = String(content.dropFirst()) }
                views.append(AnyView(headerView(content, level: 3)))
                i += 1
                continue
            }
            if trimmed.hasPrefix("##") && !trimmed.hasPrefix("###") {
                var content = String(trimmed.dropFirst(2))
                if content.hasPrefix(" ") { content = String(content.dropFirst()) }
                views.append(AnyView(headerView(content, level: 2)))
                i += 1
                continue
            }
            if trimmed.hasPrefix("#") && !trimmed.hasPrefix("##") {
                var content = String(trimmed.dropFirst(1))
                if content.hasPrefix(" ") { content = String(content.dropFirst()) }
                views.append(AnyView(headerView(content, level: 1)))
                i += 1
                continue
            }

            // Bullet list item
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                let content = String(trimmed.dropFirst(2))
                views.append(AnyView(bulletView(content)))
                i += 1
                continue
            }

            // Numbered list item
            if let range = trimmed.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
                let numberPart = String(trimmed[range]).trimmingCharacters(in: .whitespaces)
                let content = String(trimmed[range.upperBound...])
                views.append(AnyView(numberedView(number: numberPart, content: content)))
                i += 1
                continue
            }

            // Empty line - skip
            if trimmed.isEmpty {
                i += 1
                continue
            }

            // Regular paragraph - collect consecutive non-empty lines
            var paragraphLines: [String] = []
            while i < lines.count {
                let pLine = lines[i]
                let pTrimmed = pLine.trimmingCharacters(in: .whitespaces)

                // Stop if we hit a block element
                if pTrimmed.isEmpty ||
                   pTrimmed.hasPrefix("```") ||
                   pTrimmed.hasPrefix("#") ||
                   pTrimmed.hasPrefix("- ") ||
                   pTrimmed.hasPrefix("* ") ||
                   pTrimmed.range(of: #"^\d+\.\s+"#, options: .regularExpression) != nil {
                    break
                }

                paragraphLines.append(pTrimmed)
                i += 1
            }

            if !paragraphLines.isEmpty {
                let paragraphText = paragraphLines.joined(separator: " ")
                views.append(AnyView(paragraphView(paragraphText)))
            }
        }

        return views
    }

    // App blue color (same as Replace button)
    private var appBlue: Color {
        Color(red: 0.0, green: 0.584, blue: 1.0)
    }

    // MARK: - Block Views

    private func headerView(_ content: String, level: Int) -> some View {
        let fontSize: CGFloat = level == 1 ? 20 : (level == 2 ? 17 : 15)
        // Strip ** from headers since headers are already bold
        let cleanContent = content
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
        return Text(cleanContent)
            .font(.nunitoBold(size: fontSize))
            .foregroundColor(.primary)
            .padding(.top, level == 1 ? 14 : (level == 2 ? 10 : 6))
            .padding(.bottom, 2)
    }

    private func bulletView(_ content: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.nunitoRegularBold(size: 14))
                .foregroundColor(.secondary)
            inlineMarkdown(content)
        }
        .padding(.leading, 4)
    }

    private func numberedView(number: String, content: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text(number)
                .font(.nunitoRegularBold(size: 14))
                .foregroundColor(.secondary)
                .frame(minWidth: 20, alignment: .trailing)
            inlineMarkdown(content)
        }
    }

    private func paragraphView(_ content: String) -> some View {
        inlineMarkdown(content)
    }

    // MARK: - Inline Markdown Parsing

    private func inlineMarkdown(_ text: String) -> some View {
        let tokens = tokenize(text)
        var attributed = AttributedString()

        for token in tokens {
            var part: AttributedString
            switch token {
            case .plain(let str):
                part = AttributedString(str)
                part.font = .nunitoRegularBold(size: 14)
                part.foregroundColor = Color.primary.opacity(0.85)

            case .bold(let str):
                part = AttributedString(str)
                part.font = .nunitoBold(size: 14)
                part.foregroundColor = Color.primary

            case .italic(let str):
                part = AttributedString(str)
                part.font = .nunitoRegularBold(size: 14).italic()
                part.foregroundColor = Color.primary.opacity(0.85)

            case .code(let str):
                part = AttributedString(" \(str) ")
                part.font = .system(size: 12, design: .monospaced)
                part.foregroundColor = appBlue

            case .link(let linkText, let urlString):
                if let url = URL(string: urlString) {
                    part = AttributedString(linkText)
                    part.font = .nunitoRegularBold(size: 14)
                    part.foregroundColor = appBlue
                    part.link = url
                } else {
                    part = AttributedString(linkText)
                    part.font = .nunitoRegularBold(size: 14)
                    part.foregroundColor = appBlue
                }
            }
            attributed.append(part)
        }

        return Text(attributed)
            .lineSpacing(6)
            .textSelection(.enabled)
    }

    // MARK: - Tokenizer

    private enum InlineToken {
        case plain(String)
        case bold(String)
        case italic(String)
        case code(String)
        case link(text: String, url: String)
    }

    private func tokenize(_ text: String) -> [InlineToken] {
        var tokens: [InlineToken] = []
        // Normalize backticks for inline parsing too
        var remaining = text
            .replacingOccurrences(of: "`", with: "`")  // Curly backtick to straight
            .replacingOccurrences(of: "´", with: "`")  // Acute accent to backtick

        while !remaining.isEmpty {
            // Inline code `code`
            if let (fullMatch, content) = matchPattern(#"^`([^`]+)`"#, in: remaining) {
                tokens.append(.code(content))
                remaining = String(remaining.dropFirst(fullMatch.count))
                continue
            }

            // Bold **text**
            if let (fullMatch, content) = matchPattern(#"^\*\*(.+?)\*\*"#, in: remaining) {
                tokens.append(.bold(content))
                remaining = String(remaining.dropFirst(fullMatch.count))
                continue
            }

            // Bold __text__
            if let (fullMatch, content) = matchPattern(#"^__(.+?)__"#, in: remaining) {
                tokens.append(.bold(content))
                remaining = String(remaining.dropFirst(fullMatch.count))
                continue
            }

            // Italic *text*
            if let (fullMatch, content) = matchPattern(#"^\*([^*]+?)\*"#, in: remaining) {
                tokens.append(.italic(content))
                remaining = String(remaining.dropFirst(fullMatch.count))
                continue
            }

            // Italic _text_
            if let (fullMatch, content) = matchPattern(#"^_([^_]+?)_"#, in: remaining) {
                tokens.append(.italic(content))
                remaining = String(remaining.dropFirst(fullMatch.count))
                continue
            }

            // Link [text](url)
            if let (fullMatch, linkText, linkUrl) = matchLinkPattern(in: remaining) {
                tokens.append(.link(text: linkText, url: linkUrl))
                remaining = String(remaining.dropFirst(fullMatch.count))
                continue
            }

            // Plain text - consume until next special character or end
            var plainEnd = remaining.startIndex
            let specialChars: [Character] = ["`", "*", "_", "["]

            for idx in remaining.indices {
                if idx == remaining.startIndex { continue }
                if specialChars.contains(remaining[idx]) {
                    plainEnd = idx
                    break
                }
                plainEnd = remaining.index(after: idx)
            }

            if plainEnd == remaining.startIndex {
                // Single special char that didn't match a pattern - treat as plain
                plainEnd = remaining.index(after: remaining.startIndex)
            }

            let plain = String(remaining[..<plainEnd])
            tokens.append(.plain(plain))
            remaining = String(remaining[plainEnd...])
        }

        return tokens
    }

    // MARK: - Regex Helpers

    private func matchPattern(_ pattern: String, in text: String) -> (fullMatch: String, group1: String)? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let nsRange = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: nsRange) else { return nil }
        guard let fullRange = Range(match.range, in: text),
              let group1Range = Range(match.range(at: 1), in: text) else { return nil }
        return (String(text[fullRange]), String(text[group1Range]))
    }

    private func matchLinkPattern(in text: String) -> (fullMatch: String, linkText: String, url: String)? {
        let pattern = #"^\[([^\]]+)\]\(([^)]+)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let nsRange = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: nsRange) else { return nil }
        guard let fullRange = Range(match.range, in: text),
              let textRange = Range(match.range(at: 1), in: text),
              let urlRange = Range(match.range(at: 2), in: text) else { return nil }
        return (String(text[fullRange]), String(text[textRange]), String(text[urlRange]))
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        MarkdownView(text: """
        # Header 1
        ## Header 2
        ### Header 3

        This is a paragraph with **bold text** and *italic text*.

        Here's some `inline code` in a sentence.

        - First bullet point
        - Second bullet with **bold**
        - Third with `code`

        1. Numbered item one
        2. Numbered item two

        ```swift
        func hello() {
            print("Hello, World!")
        }
        ```

        Check out this [link](https://example.com).
        """)
        .padding()
    }
    .frame(width: 400, height: 600)
}
