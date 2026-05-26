import ActionKit
import ApplicationServices

extension ActionExecutor {
  func executeKeyboardShortcut(_ shortcut: String) async -> ActionResult {
    guard let parsedShortcut = KeyboardShortcutParser.parse(shortcut) else {
      let actionError = ActionError.invalidInput("Failed to parse keyboard shortcut")
      configuration.log(.warning, actionError.diagnosticMessage)
      return .failure(actionError)
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
    guard await configuration.permissions.ensureAccessibility() else {
      return .failure(.permissionDenied(.accessibility))
    }

    guard dependencies.keyEventPoster.postKeyStroke(virtualKey: virtualKey, flags: flags) else {
      let actionError = ActionError.internalError("Failed to post key stroke event")
      configuration.log(.error, actionError.diagnosticMessage)
      return .failure(actionError)
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
