import Foundation
import MarkdownToHTMLCore

@main
struct MarkdownToHTMLApp {
    static func main() {
        print("=== Markdown to HTML Converter ===")
        print("Type your Markdown content below. Enter a single line with END to finish.\n")

        let markdown = readMarkdownInput()

        if markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("No Markdown content provided. Exiting.")
            return
        }

        let converter = MarkdownConverter()
        let convertedHTML = converter.convert(markdown)
        let htmlDocument = wrapInHTMLDocument(convertedHTML)

        do {
            let fileURL = try writeHTMLDocument(htmlDocument)
            print("HTML has been generated at: \(fileURL.path)")
            openHTMLDocument(at: fileURL)
        } catch {
            print("Failed to write HTML file: \(error.localizedDescription)")
        }
    }

    private static func readMarkdownInput() -> String {
        var lines: [String] = []
        while let line = readLine() {
            if line == "END" {
                break
            }
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }

    private static func wrapInHTMLDocument(_ bodyContent: String) -> String {
        """
        <!DOCTYPE html>
        <html lang=\"en\">
        <head>
            <meta charset=\"utf-8\">
            <title>Markdown Preview</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
                    margin: 40px auto;
                    max-width: 800px;
                    line-height: 1.6;
                    color: #333;
                }
                pre {
                    background: #f6f8fa;
                    padding: 12px;
                    overflow-x: auto;
                }
                code {
                    background: #f6f8fa;
                    padding: 2px 4px;
                    border-radius: 4px;
                }
                img {
                    max-width: 100%;
                    height: auto;
                }
            </style>
        </head>
        <body>
        \(bodyContent)
        </body>
        </html>
        """
    }

    private static func writeHTMLDocument(_ html: String) throws -> URL {
        let fileManager = FileManager.default
        let temporaryDirectory = fileManager.temporaryDirectory
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let filename = "markdown-preview-\(formatter.string(from: Date())).html"
        let fileURL = temporaryDirectory.appendingPathComponent(filename)
        try html.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    private static func openHTMLDocument(at url: URL) {
        #if os(macOS)
        let openCommand = "/usr/bin/open"
        #else
        let openCommand = "/usr/bin/xdg-open"
        #endif

        guard FileManager.default.isExecutableFile(atPath: openCommand) else {
            print("Could not find a system tool to open the HTML document automatically.")
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: openCommand)
        process.arguments = [url.path]

        do {
            try process.run()
        } catch {
            print("Failed to open the HTML document automatically: \(error.localizedDescription)")
        }
    }
}
