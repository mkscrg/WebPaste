import XCTest
@testable import WebPaste

final class WebPasteTests: XCTestCase {
    func testCleanHtmlDropMeta() throws {
        let input = "<meta charset=\"UTF-8\"><span><b>hello</b> world</span>"
        let expected = "<span><b>hello</b> world</span>"
        let output = WebPaste.cleanHtml(input)
        XCTAssertEqual(output, expected, "unexpected HTML from cleanHtml()")
    }

    func testCleanHtmlAppleConvertedSpace() throws {
        let input = "<span><b>hello</b><span class=\"Apple-converted-space\"> </span>world</span>"
        let expected = "<span><b>hello</b> world</span>"
        let output = WebPaste.cleanHtml(input)
        XCTAssertEqual(output, expected, "unexpected HTML from cleanHtml()")
    }

    func testCleanHtmlGDocsBGuid() throws {
        let input = "<b id=\"docs-internal-guid-aba9a7ab-f7ff-ee4a-c0b7-fadd5106ffca\"><span><b>hello</b> world</span></b>"
        let expected = "<span><b>hello</b> world</span>"
        let output = WebPaste.cleanHtml(input)
        XCTAssertEqual(output, expected, "unexpected HTML from cleanHtml()")
    }

    func testCleanHtmlConvertPDiv() throws {
        let input = "<p>hello</p><p>world</p>"
        let expected = "<div>hello</div><div>world</div>"
        let output = WebPaste.cleanHtml(input)
        XCTAssertEqual(output, expected, "unexpected HTML from cleanHtml()")
    }

    func testCleanHtmlDropLoneDiv() throws {
        let input = "<ul><li><div>hello</div></li><li><div>world</div></li></ul>"
        let expected = "<ul><li>hello</li><li>world</li></ul>"
        let output = WebPaste.cleanHtml(input)
        XCTAssertEqual(output, expected, "unexpected HTML from cleanHtml()")
    }

    func testCleanHtmlTagStyleConflict() throws {
        let inputs = [
            "<em style=\"font-style: normal\">hello world</em>",
            "<i style=\"font-style: normal\">hello world</i>",
            "<b style=\"font-weight: normal\">hello world</b>",
            "<strong style=\"font-weight: 400\">hello world</strong>"
        ]
        let expected = "<span>hello world</span>"
        for input in inputs {
            let output = WebPaste.cleanHtml(input)
            XCTAssertEqual(output, expected, "unexpected HTML from cleanHtml()")
        }
    }

    func testCleanHtmlStyleInject() throws {
        let inputsExpected = [
            (
                 "<span style=\"font-style: italic\">hello world</span>",
                 "<span><i>hello world</i></span>"
            ),
            (
                 "<span style=\"font-weight: bold\">hello world</span>",
                 "<span><b>hello world</b></span>"
            ),
            (
                 "<span style=\"font-weight: 700\">hello world</span>",
                 "<span><b>hello world</b></span>"
            ),
            (
                 "<span style=\"text-decoration: underline\">hello world</span>",
                 "<span><u>hello world</u></span>"
            ),
            (
                 "<span style=\"text-decoration: line-through\">hello world</span>",
                 "<span><strike>hello world</strike></span>"
            )
        ]
        for (input, expected) in inputsExpected {
            let output = WebPaste.cleanHtml(input)
            XCTAssertEqual(output, expected, "unexpected HTML from cleanHtml()")
        }
    }

    func testCleanHtmlDropNonAHrefAttrs() throws {
        let input = "<span id=\"outer\">hello <a id=\"link\" href=\"foobar\">world</a></span>"
        let output = WebPaste.cleanHtml(input)
        let expected = "<span>hello <a href=\"foobar\">world</a></span>"
        XCTAssertEqual(output, expected, "unexpected HTML from cleanHtml()")
    }
}
