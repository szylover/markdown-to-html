import XCTest
@testable import markdown_to_html

final class MarkdownConverterTests: XCTestCase {
    private var converter: MarkdownConverter!

    override func setUp() {
        super.setUp()
        converter = MarkdownConverter()
    }

    func testHeadingConversion() {
        let markdown = "# Title\n## Subtitle"
        let expected = "<h1>Title</h1>\n<h2>Subtitle</h2>"
        XCTAssertEqual(converter.convert(markdown), expected)
    }

    func testParagraphAndInlineFormatting() {
        let markdown = "This is **bold** and *italic* text."
        let expected = "<p>This is <strong>bold</strong> and <em>italic</em> text.</p>"
        XCTAssertEqual(converter.convert(markdown), expected)
    }

    func testInlineCodeEscapesHTML() {
        let markdown = "Use `print(<value>)` to debug."
        let expected = "<p>Use <code>print(&lt;value&gt;)</code> to debug.</p>"
        XCTAssertEqual(converter.convert(markdown), expected)
    }

    func testUnorderedList() {
        let markdown = "- One\n- Two\n\nParagraph"
        let expected = "<ul>\n<li>One</li>\n<li>Two</li>\n</ul>\n<p>Paragraph</p>"
        XCTAssertEqual(converter.convert(markdown), expected)
    }

    func testEscapesHTMLOutsideFormatting() {
        let markdown = "<script>alert('xss')</script>"
        let expected = "<p>&lt;script&gt;alert('xss')&lt;/script&gt;</p>"
        XCTAssertEqual(converter.convert(markdown), expected)
    }
}
