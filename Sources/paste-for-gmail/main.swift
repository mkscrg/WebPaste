import Cocoa

main()

private func main() {
    if !checkAccessibility() {
        print("Accessibility permission not granted")
        exit(1)
    }

    sendCommandV()
}

private func checkAccessibility() -> Bool {
    let checkOptPromptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
    let options = [checkOptPromptKey: true]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
}

private func sendCommandV() {
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
