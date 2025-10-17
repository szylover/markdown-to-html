import Foundation

public struct MarkdownConverter {
    private enum ListType: Equatable {
        case unordered
        case ordered
    }

    public init() {}

    public func convert(_ markdown: String) -> String {
        var htmlBlocks: [String] = []
        var paragraphLines: [String] = []
        var currentListType: ListType? = nil
        var inCommentBlock = false

        func flushParagraph() {
            guard !paragraphLines.isEmpty else { return }
            let paragraphText = paragraphLines.joined(separator: " ")
            htmlBlocks.append("<p>\(renderInline(paragraphText))</p>")
            paragraphLines.removeAll()
        }

        func closeList() {
            guard let listType = currentListType else { return }
            switch listType {
            case .unordered:
                htmlBlocks.append("</ul>")
            case .ordered:
                htmlBlocks.append("</ol>")
            }
            currentListType = nil
        }

        let lines = markdown.split(maxSplits: .max, omittingEmptySubsequences: false, whereSeparator: { $0.isNewline })
        for rawLine in lines {
            let line = String(rawLine)
            let trimmed = line.trimmingCharacters(in: CharacterSet.whitespaces)

            if inCommentBlock {
                if trimmed.contains("-->") {
                    inCommentBlock = false
                }
                continue
            }

            if trimmed.hasPrefix("<!--") {
                flushParagraph()
                if !trimmed.contains("-->") {
                    inCommentBlock = true
                }
                continue
            }

            if trimmed.isEmpty {
                flushParagraph()
                closeList()
                continue
            }

            if let heading = headingHTML(from: trimmed) {
                flushParagraph()
                closeList()
                htmlBlocks.append(heading)
                continue
            }

            if let (listItem, listType) = listItemHTML(from: trimmed) {
                flushParagraph()
                if currentListType != listType {
                    closeList()
                    switch listType {
                    case .unordered:
                        htmlBlocks.append("<ul>")
                    case .ordered:
                        htmlBlocks.append("<ol>")
                    }
                    currentListType = listType
                }
                htmlBlocks.append(listItem)
                continue
            }

            paragraphLines.append(trimmed)
        }

        flushParagraph()
        closeList()

        return htmlBlocks.joined(separator: "\n")
    }

    private func headingHTML(from line: String) -> String? {
        let prefixCount = line.prefix { $0 == "#" }.count
        guard prefixCount > 0 else { return nil }

        let level = min(prefixCount, 6)
        let content = line.drop(while: { $0 == "#" })
            .drop(while: { $0 == " " })
        let rendered = renderInline(String(content))
        return "<h\(level)>\(rendered)</h\(level)>"
    }

    private func listItemHTML(from line: String) -> (String, ListType)? {
        if let unorderedContent = unorderedListContent(from: line) {
            let rendered = renderListItemContent(unorderedContent)
            return ("<li>\(rendered)</li>", .unordered)
        }

        if let orderedContent = orderedListContent(from: line) {
            let rendered = renderListItemContent(orderedContent)
            return ("<li>\(rendered)</li>", .ordered)
        }

        return nil
    }

    private func unorderedListContent(from line: String) -> String? {
        guard line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") else {
            return nil
        }
        return String(line.dropFirst(2))
    }

    private func orderedListContent(from line: String) -> String? {
        guard let dotIndex = line.firstIndex(of: ".") else { return nil }
        let numberPart = line[..<dotIndex]
        guard !numberPart.isEmpty, numberPart.allSatisfy({ $0.isNumber }) else {
            return nil
        }
        let contentStart = line.index(after: dotIndex)
        if contentStart == line.endIndex {
            return ""
        }
        let remainder = line[contentStart...]
        if remainder.first.map({ !$0.isWhitespace && $0 != "[" }) == true {
            return nil
        }
        let content = remainder.drop(while: { $0.isWhitespace })
        return String(content)
    }

    private func renderListItemContent(_ content: String) -> String {
        if let checkbox = checkboxHTML(from: content) {
            return checkbox
        }
        return renderInline(content)
    }

    private func checkboxHTML(from content: String) -> String? {
        guard content.hasPrefix("["), content.count >= 3 else { return nil }
        let secondIndex = content.index(after: content.startIndex)
        let thirdIndex = content.index(after: secondIndex)
        guard content[thirdIndex] == "]" else { return nil }
        let marker = content[secondIndex]
        guard marker == " " || marker == "x" || marker == "X" else { return nil }
        let isChecked = marker == "x" || marker == "X"
        let remainderStart = content.index(after: thirdIndex)
        let remainder = content[remainderStart...]
        let trimmedRemainder = remainder.drop(while: { $0.isWhitespace })
        let input = "<input type=\"checkbox\" disabled\(isChecked ? " checked" : "")>"
        if trimmedRemainder.isEmpty {
            return input
        }
        let rendered = renderInline(String(trimmedRemainder))
        return "<label>\(input) \(rendered)</label>"
    }

    private func renderInline(_ text: String) -> String {
        var result = ""
        var buffer = ""
        var inCode = false

        func appendBuffer() {
            if buffer.isEmpty && !inCode { return }
            if inCode {
                result.append("<code>\(escapeHTML(buffer))</code>")
            } else {
                let escaped = escapeHTML(buffer)
                result.append(applyInlineFormats(to: escaped))
            }
            buffer.removeAll(keepingCapacity: true)
        }

        for character in text {
            if character == "`" {
                appendBuffer()
                inCode.toggle()
                continue
            }
            buffer.append(character)
        }

        if inCode {
            result.append("`")
            result.append(applyInlineFormats(to: escapeHTML(buffer)))
        } else {
            appendBuffer()
        }

        return result
    }

    private func escapeHTML(_ text: String) -> String {
        var escaped = text
        let entities: [(character: String, entity: String)] = [
            ("&", "&amp;"),
            ("<", "&lt;"),
            (">", "&gt;")
        ]
        for (character, entity) in entities {
            escaped = escaped.replacingOccurrences(of: character, with: entity)
        }
        return escaped
    }

    private func applyInlineFormats(to text: String) -> String {
        let imageRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let withImages = MarkdownConverter.imageRegex.stringByReplacingMatches(
            in: text,
            options: [],
            range: imageRange,
            withTemplate: "<img src=\"$2\" alt=\"$1\" />"
        )

        let linkRange = NSRange(withImages.startIndex..<withImages.endIndex, in: withImages)
        let withLinks = MarkdownConverter.linkRegex.stringByReplacingMatches(
            in: withImages,
            options: [],
            range: linkRange,
            withTemplate: "<a href=\"$2\">$1</a>"
        )

        let strongRange = NSRange(withLinks.startIndex..<withLinks.endIndex, in: withLinks)
        let boldApplied = MarkdownConverter.strongRegex.stringByReplacingMatches(
            in: withLinks,
            options: [],
            range: strongRange,
            withTemplate: "<strong>$1</strong>"
        )

        let italicRange = NSRange(boldApplied.startIndex..<boldApplied.endIndex, in: boldApplied)
        let italicApplied = MarkdownConverter.emphasisRegex.stringByReplacingMatches(
            in: boldApplied,
            options: [],
            range: italicRange,
            withTemplate: "<em>$1</em>"
        )

        return italicApplied
    }

    private static let strongRegex: NSRegularExpression = {
        return try! NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*", options: [])
    }()

    private static let emphasisRegex: NSRegularExpression = {
        return try! NSRegularExpression(pattern: "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)", options: [])
    }()

    private static let imageRegex: NSRegularExpression = {
        return try! NSRegularExpression(pattern: "!\\[([^\\]]*)\\]\\(([^\\)]+)\\)", options: [])
    }()

    private static let linkRegex: NSRegularExpression = {
        return try! NSRegularExpression(pattern: "(?<!\\!)\\[([^\\]]+)\\]\\(([^\\)]+)\\)", options: [])
    }()
}
