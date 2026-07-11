import ApplicationServices

package struct KeyStrokeEventPoster: Sendable {
  private let makeKeyEvent: @Sendable (CGKeyCode, CGEventFlags, Bool) -> CGEvent?
  private let postKeyEvent: @Sendable (CGEvent) -> Void

  package init(
    makeKeyEvent: @escaping @Sendable (CGKeyCode, CGEventFlags, Bool) -> CGEvent? = {
      Self.makeKeyEvent(virtualKey: $0, flags: $1, keyDown: $2)
    },
    postKeyEvent: @escaping @Sendable (CGEvent) -> Void
  ) {
    self.makeKeyEvent = makeKeyEvent
    self.postKeyEvent = postKeyEvent
  }

  package func postKeyStroke(virtualKey: CGKeyCode, flags: CGEventFlags) -> Bool {
    guard
      let keyDownEvent = makeKeyEvent(virtualKey, flags, true),
      let keyUpEvent = makeKeyEvent(virtualKey, flags, false)
    else {
      return false
    }

    postKeyEvent(keyDownEvent)
    postKeyEvent(keyUpEvent)
    return true
  }

  private static func makeKeyEvent(
    virtualKey: CGKeyCode,
    flags: CGEventFlags,
    keyDown: Bool
  ) -> CGEvent? {
    guard
      let event = CGEvent(
        keyboardEventSource: nil,
        virtualKey: virtualKey,
        keyDown: keyDown
      )
    else {
      return nil
    }
    event.flags = flags
    return event
  }
}
