import ActionKit
import ApplicationServices

extension ActionExecutor {
  func executeKeyboardShortcut(_ shortcut: String) async -> ActionResult {
    guard let parsedShortcut = KeyboardShortcutParser.parse(shortcut) else {
      return invalidInputResult("Failed to parse keyboard shortcut")
    }

    return await executeKeyStroke(
      virtualKey: parsedShortcut.virtualKey,
      flags: parsedShortcut.modifiers
    )
  }

  func executeKeyEvent(_ event: ActionKeyStroke) async -> ActionResult {
    await executeKeyStroke(
      virtualKey: CGKeyCode(event.virtualKeyCode),
      flags: event.modifiers.toCGEventFlags()
    )
  }

  private func executeKeyStroke(virtualKey: CGKeyCode, flags: CGEventFlags) async -> ActionResult {
    guard dependencies.keyEventPoster.postKeyStroke(virtualKey: virtualKey, flags: flags) else {
      return internalErrorResult("Failed to post key stroke event")
    }
    return .success
  }
}

extension ActionModifiers {
  fileprivate func toCGEventFlags() -> CGEventFlags {
    var flags: CGEventFlags = []
    if contains(.command) { flags.insert(.maskCommand) }
    if contains(.shift) { flags.insert(.maskShift) }
    if contains(.option) { flags.insert(.maskAlternate) }
    if contains(.control) { flags.insert(.maskControl) }
    if contains(.function) { flags.insert(.maskSecondaryFn) }
    return flags
  }
}
