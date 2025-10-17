import XCTest
@testable import MarkdownToHTMLCore

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

    func testOrderedListConversion() {
        let markdown = "1. First\n2. Second"
        let expected = "<ol>\n<li>First</li>\n<li>Second</li>\n</ol>"
        XCTAssertEqual(converter.convert(markdown), expected)
    }

    func testIgnoresHTMLComments() {
        let markdown = "# Heading\n<!-- comment -->\nContent"
        let expected = "<h1>Heading</h1>\n<p>Content</p>"
        XCTAssertEqual(converter.convert(markdown), expected)
    }

    func testImageAndLinkRendering() {
        let markdown = "![Alt](image.png) and [Link](https://example.com)"
        let expected = "<p><img src=\"image.png\" alt=\"Alt\" /> and <a href=\"https://example.com\">Link</a></p>"
        XCTAssertEqual(converter.convert(markdown), expected)
    }

    func testTaskListItems() {
        let markdown = "- [x] Done\n- [ ] Pending"
        let expected = "<ul>\n<li><label><input type=\"checkbox\" disabled checked> Done</label></li>\n<li><label><input type=\"checkbox\" disabled> Pending</label></li>\n</ul>"
        XCTAssertEqual(converter.convert(markdown), expected)
    }
}
