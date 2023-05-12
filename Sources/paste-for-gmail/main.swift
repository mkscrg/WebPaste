import Cocoa

PasteForGmail.main()

struct PasteForGmail {
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

        let htmlOut = cleanHtml(html!)
        let plainOut = plain

        writePasteboard(html: htmlOut, plain: plainOut)

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

    static func writePasteboard(html: String?, plain: String?) {
        let pboard = NSPasteboard.general
        pboard.clearContents()

        var types: [NSPasteboard.PasteboardType] = []
        if html != nil {
            types.append(htmlType)
        }
        if plain != nil {
            types.append(plainType)
        }
        pboard.declareTypes(types, owner: nil)

        if html != nil {
            pboard.setString(html!, forType: htmlType)
        }
        if plain != nil {
            pboard.setString(plain!, forType: plainType)
        }
    }

    // html transform

    static func cleanHtml(_ html: String) -> String {
        return "<span><b>TODO:</b> transform HTML</span>"
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
