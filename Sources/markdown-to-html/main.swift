import Foundation
import MarkdownToHTMLCore

@main
struct MarkdownToHTMLApp {
    static func main() {
        print("=== Markdown to HTML Converter ===")

        guard let markdown = obtainMarkdownFromUser() else {
            print("No Markdown content provided. Exiting.")
            return
        }

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

    private static func obtainMarkdownFromUser() -> String? {
        if let markdown = promptForMarkdownThroughGUI() {
            return markdown
        }

        print("Unable to open a graphical input window. Paste your Markdown content below.")
        print("Press Ctrl+D (Unix/macOS) or Ctrl+Z followed by Enter (Windows Subsystem for Linux) when finished.\n")

        guard let data = try? FileHandle.standardInput.readToEnd() else {
            return nil
        }

        guard let markdown = String(data: data, encoding: .utf8) else {
            return nil
        }

        return markdown
    }

    private static func promptForMarkdownThroughGUI() -> String? {
#if os(macOS)
        return promptForMarkdownWithAppleScript()
#else
        return promptForMarkdownWithZenity()
#endif
    }

#if os(macOS)
    private static func promptForMarkdownWithAppleScript() -> String? {
        guard let executable = findExecutable(named: "osascript") else {
            return nil
        }

        let script = """
        tell application "System Events"
            activate
            set dialogResult to display dialog "Enter Markdown content:" with title "Markdown Input" default answer "" buttons {"Cancel", "OK"} default button "OK"
            return text returned of dialogResult
        end tell
        """

        return runProcess(executablePath: executable, arguments: ["-e", script])
    }
#else
    private static func promptForMarkdownWithZenity() -> String? {
        guard let executable = findExecutable(named: "zenity") else {
            return nil
        }

        return runProcess(
            executablePath: executable,
            arguments: [
                "--text-info",
                "--editable",
                "--title=Markdown Input",
                "--width=600",
                "--height=400"
            ]
        )
    }
#endif

    private static func runProcess(executablePath: String, arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                return nil
            }

            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            guard var output = String(data: data, encoding: .utf8) else {
                return nil
            }

            while output.last?.isNewline == true {
                output.removeLast()
            }

            return output
        } catch {
            return nil
        }
    }

    private static func findExecutable(named name: String) -> String? {
        let fileManager = FileManager.default
        var searchDirectories: [String] = []

        if let pathVariable = ProcessInfo.processInfo.environment["PATH"] {
            searchDirectories.append(contentsOf: pathVariable.split(separator: ":").map(String.init))
        }

        searchDirectories.append(contentsOf: ["/usr/bin", "/usr/local/bin", "/bin", "/opt/homebrew/bin", "/opt/local/bin"])

        var checked = Set<String>()

        for directory in searchDirectories where checked.insert(directory).inserted {
            let path = directory + "/" + name
            if fileManager.isExecutableFile(atPath: path) {
                return path
            }
        }

        return nil
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
