import Cocoa
import SwiftSoup

@main
struct WebPaste {
    static func main() {
        if !checkAccessibility() {
            print("Accessibility permission not granted")
            exit(1)
        }

        let (html, plain) = readPasteboard()
        if html == nil {
            print("No HTML in clipboard")
            exit(1)
        }
        if plain == nil {
            print("No plaintext in clipboard (unexpected!)")
            exit(1)
        }

        let htmlOut = cleanHtml(html!)
        if htmlOut == nil {
            // assume cleanHtml printed the error
            exit(1)
        }

        writePasteboard(html: htmlOut!, plain: plain!)

        sendCommandV()
    }

    // privileges

    static func checkAccessibility() -> Bool {
        let checkOptPromptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [checkOptPromptKey: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    // pasteboard

    static let htmlType = NSPasteboard.PasteboardType.html
    static let plainType = NSPasteboard.PasteboardType.string

    static func readPasteboard() -> (String?, String?) {
        let pboard = NSPasteboard.general
        return (pboard.string(forType: htmlType), pboard.string(forType: plainType))
    }

    static func writePasteboard(html: String, plain: String) {
        let pboard = NSPasteboard.general
        pboard.clearContents()
        pboard.declareTypes([htmlType, plainType], owner: nil)
        pboard.setString(html, forType: htmlType)
        pboard.setString(plain, forType: plainType)
    }

    // html transform

    static func cleanHtml(_ html: String) -> String? {
        do {
            let doc = try SwiftSoup.parseBodyFragment(html)
            let body = doc.body()!
            try cleanHtmlTree(body)
            doc.outputSettings()
                .prettyPrint(pretty: false)
                .escapeMode(Entities.EscapeMode.base)
            return try body.html()
        } catch {
            print("Error cleaning HTML: \(error)")
            return nil
        }
    }

    // TODO should use traverse() to avoid the rec call
    static func cleanHtmlTree(_ elt: Element) throws {
        for child in elt.children() {
            try cleanHtmlTree(child)
        }
        try cleanHtmlElement(elt)
    }

    static let styleFSNormal = #/(^|;) *font-style: *normal *(;|$)/#
    static let styleFWNormal = #/(^|;) *font-weight: *(normal|400) *(;|$)/#

    static let styleFSItalic = #/(^|;) *font-style: *italic *(;|$)/#
    static let styleFWBold = #/(^|;) *font-weight: *(bold|700) *(;|$)/#
    static let styleTDUnderline = #/(^|;) *text-decoration: *([a-zA-Z0-9-]+ +)*underline( +[a-zA-Z0-9-]+)* *(;|$)/#
    static let styleTDLineThrough = #/(^|;) *text-decoration: *([a-zA-Z0-9-]+ +)*line-through( +[a-zA-Z0-9-]+)* *(;|$)/#

    static func cleanHtmlElement(_ elt: Element) throws {
        // most of these return, but some don't. order sensitive!

        // drop <meta>
        if elt.tagName() == "meta" {
            try elt.remove()
            return
        }
        // convert "Apple-converted-space" to simple spaces
        if (try? elt.className()) ?? "" == "Apple-converted-space" {
            try elt.replaceWith(TextNode(" ", nil))
            return
        }
        // drop <b> w/ google docs guid
        if elt.tagName() == "b" && elt.id().starts(with: "docs-internal-guid-") {
            try replaceWithChildren(elt)
            return
        }

        // convert <p> to <div>
        if elt.tagName() == "p" {
            try elt.tagName("div")
            // no early return!
        }

        // drop lone-sibling <div>
        if elt.tagName() == "div" && elt.parent()!.childNodeSize() == 1 {
            try replaceWithChildren(elt)
            return
        }

        // resolve tag-style contradictions
        if try elt.tagName() == "em" && elt.attr("style").contains(styleFSNormal)
            || elt.tagName() == "i" && elt.attr("style").contains(styleFSNormal)
            || elt.tagName() == "b" && elt.attr("style").contains(styleFWNormal)
            || elt.tagName() == "strong" && elt.attr("style").contains(styleFWNormal) {
            try elt.tagName("span")
            // no early return!
        }

        // test `style`, inject <i>/<b>/<u>/<strike> tags accordingly
        if elt.tagName() == "span" {
            if try elt.attr("style").contains(styleFSItalic) {
                try parentOfChildren(elt, tagName: "i")
            }
            if try elt.attr("style").contains(styleFWBold) {
                try parentOfChildren(elt, tagName: "b")
            }
            if try elt.attr("style").contains(styleTDUnderline) {
                try parentOfChildren(elt, tagName: "u")
            }
            if try elt.attr("style").contains(styleTDLineThrough) {
                try parentOfChildren(elt, tagName: "strike")
            }
            // no early return!
        }

        // drop all attrs except "href" on <a>
        var href: String?
        if elt.tagName() == "a" {
            href = try elt.attr("href")
        }
        for attr in elt.getAttributes() ?? Attributes() {
            try elt.removeAttr(attr.getKey())
        }
        if href != nil {
            try elt.attr("href", href!)
        }
    }

    static func replaceWithChildren(_ elt: Element) throws {
        let parent = elt.parent()!
        let baseIdx = try elt.elementSiblingIndex()

        try elt.remove()
        for (idx, child) in elt.getChildNodes().enumerated() {
            try child.remove()
            try parent.addChildren(baseIdx + idx, child)
        }
    }

    static func parentOfChildren(_ elt: Element, tagName: String) throws {
        let newChild = try elt.prependElement(tagName)
        for (idx, child) in elt.getChildNodes().enumerated() {
            if idx == 0 {
                continue // first child is newChild
            }
            try child.remove()
            try newChild.addChildren(child)
        }
    }

    // command-V

    static func sendCommandV() {
        let cmdKey = 55 as CGKeyCode
        let vKey = 9 as CGKeyCode

        let src = CGEventSource(stateID: .hidSystemState)

        let cmdDown = CGEvent(keyboardEventSource: src, virtualKey: cmdKey, keyDown: true)
        cmdDown!.setIntegerValueField(.keyboardEventAutorepeat, value: 1)
        cmdDown!.post(tap: .cghidEventTap)

        let vDown = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: true)
        vDown!.flags = .maskCommand
        vDown!.post(tap: .cghidEventTap)

        let vUp = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: false)
        vUp!.flags = .maskCommand
        vUp!.post(tap: .cghidEventTap)

        let cmdUp = CGEvent(keyboardEventSource: src, virtualKey: cmdKey, keyDown: false)
        cmdUp!.post(tap: .cghidEventTap)
    }
}
