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
            try cleanBody(body)
            doc.outputSettings()
                .prettyPrint(pretty: false)
                .escapeMode(Entities.EscapeMode.base)
            return try body.html()
        } catch {
            print("Error cleaning HTML: \(error)")
            return nil
        }
    }

    static func cleanBody(_ body: Element) throws {
        for eltOp in elementOps {
            try body.traverse(eltOp)
        }
    }

    static let elementOps = [
        // drop <meta>
        ElementOp { (elt: Element, _: Int) throws in
            if elt.tagName() == "meta" {
                try elt.remove()
            }
        },

        // convert "Apple-converted-space" to simple spaces
        ElementOp { (elt: Element, _: Int) throws in
            if (try? elt.className()) ?? "" == "Apple-converted-space" {
                try elt.replaceWith(TextNode(" ", nil))
            }
        },

        // drop <b> w/ google docs guid
        ElementOp { (elt: Element, _: Int) throws in
            if elt.tagName() == "b" && elt.id().starts(with: "docs-internal-guid-") {
                try replaceWithChildren(elt)
            }
        },

        // insert <br> between consecutive <p>
        ElementOp { (elt: Element, _: Int) throws in
            let nextSib = try elt.nextElementSibling()
            if let nextSib {
                if elt.tagName() == "p" && nextSib.tagName() == "p" {
                    try elt.after("<br>")
                }
            }
        },

        // convert <p> to <div>
        ElementOp { (elt: Element, _: Int) throws in
            if elt.tagName() == "p" {
                try elt.tagName("div")
            }
        },

        // drop lone-sibling <div>
        ElementOp { (elt: Element, _: Int) throws in
            if elt.tagName() == "div" && elt.parent()!.childNodeSize() == 1 {
                try replaceWithChildren(elt)
            }
        },

        // resolve tag-style contradictions
        ElementOp { (elt: Element, _: Int) throws in
            if try elt.tagName() == "em" && elt.attr("style").contains(styleFSNormal)
                || elt.tagName() == "i" && elt.attr("style").contains(styleFSNormal)
                || elt.tagName() == "b" && elt.attr("style").contains(styleFWNormal)
                || elt.tagName() == "strong" && elt.attr("style").contains(styleFWNormal) {
                try elt.tagName("span")
            }
        },

        // test `style`, inject <i>/<b>/<u>/<strike> tags accordingly
        ElementOp { (elt: Element, _: Int) throws in
            if elt.tagName() == "span" {
                if try elt.attr("style").contains(styleFSItalic) {
                    try insertParentOfChildren(elt, tagName: "i")
                }
                if try elt.attr("style").contains(styleFWBold) {
                    try insertParentOfChildren(elt, tagName: "b")
                }
                if try elt.attr("style").contains(styleTDUnderline) {
                    try insertParentOfChildren(elt, tagName: "u")
                }
                if try elt.attr("style").contains(styleTDLineThrough) {
                    try insertParentOfChildren(elt, tagName: "strike")
                }
            }
        },

        // drop all attrs except "href" on <a>
        ElementOp { (elt: Element, _: Int) throws in
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
    ]

    static let styleFSNormal = #/(^|;) *font-style: *normal *(;|$)/#
    static let styleFWNormal = #/(^|;) *font-weight: *(normal|400) *(;|$)/#

    static let styleFSItalic = #/(^|;) *font-style: *italic *(;|$)/#
    static let styleFWBold = #/(^|;) *font-weight: *(bold|700) *(;|$)/#
    static let styleTDUnderline = #/(^|;) *text-decoration: *([a-zA-Z0-9-]+ +)*underline( +[a-zA-Z0-9-]+)* *(;|$)/#
    static let styleTDLineThrough = #/(^|;) *text-decoration: *([a-zA-Z0-9-]+ +)*line-through( +[a-zA-Z0-9-]+)* *(;|$)/#

    static func replaceWithChildren(_ elt: Element) throws {
        let parent = elt.parent()!
        let baseIdx = try elt.elementSiblingIndex()

        try elt.remove()
        for (idx, child) in elt.getChildNodes().enumerated() {
            try child.remove()
            try parent.addChildren(baseIdx + idx, child)
        }
    }

    static func insertParentOfChildren(_ elt: Element, tagName: String) throws {
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

struct ElementOp: NodeVisitor {
    var run: (Element, Int) throws -> Void

    func head(_ node: Node, _ depth: Int) throws {
        // do nothing, always run leaf->root
    }

    func tail(_ node: Node, _ depth: Int) throws {
        if let elt = node as? Element {
            try run(elt, depth)
        }
    }
}
