import Foundation

public struct MarkdownConverter {
    public init() {}

    public func convert(_ markdown: String) -> String {
        var htmlBlocks: [String] = []
        var paragraphLines: [String] = []
        var inList = false

        func flushParagraph() {
            guard !paragraphLines.isEmpty else { return }
            let paragraphText = paragraphLines.joined(separator: " ")
            htmlBlocks.append("<p>\(renderInline(paragraphText))</p>")
            paragraphLines.removeAll()
        }

        func closeList() {
            if inList {
                htmlBlocks.append("</ul>")
                inList = false
            }
        }

        let lines = markdown.split(maxSplits: .max, omittingEmptySubsequences: false, whereSeparator: { $0.isNewline })
        for rawLine in lines {
            let line = String(rawLine)
            let trimmed = line.trimmingCharacters(in: CharacterSet.whitespaces)

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

            if let listItem = listItemHTML(from: trimmed) {
                flushParagraph()
                if !inList {
                    htmlBlocks.append("<ul>")
                    inList = true
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

    private func listItemHTML(from line: String) -> String? {
        guard line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") else {
            return nil
        }
        let content = line.dropFirst(2)
        let rendered = renderInline(String(content))
        return "<li>\(rendered)</li>"
    }

    private func renderInline(_ text: String) -> String {
        var result = ""
        var buffer = ""
        var inCode = false

        func appendBuffer() {
            if inCode {
                result.append("<code>\(escapeHTML(buffer))</code>")
            } else {
                result.append(applyEmphasis(to: escapeHTML(buffer)))
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
            result.append(applyEmphasis(to: escapeHTML(buffer)))
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

    private func applyEmphasis(to text: String) -> String {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let boldApplied = MarkdownConverter.strongRegex.stringByReplacingMatches(
            in: text,
            options: [],
            range: range,
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
}
