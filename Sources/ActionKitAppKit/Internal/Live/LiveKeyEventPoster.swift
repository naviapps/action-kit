import ApplicationServices

struct LiveKeyEventPoster: KeyEventPosting {
  typealias KeyEventFactory = @Sendable (CGKeyCode, CGEventFlags, Bool) -> CGEvent?

  private let makeKeyEvent: KeyEventFactory
  private let postKeyEvent: @Sendable (CGEvent) -> Void

  init(
    makeKeyEvent: @escaping KeyEventFactory = {
      Self.makeKeyEvent(virtualKey: $0, flags: $1, keyDown: $2)
    },
    postKeyEvent: @escaping @Sendable (CGEvent) -> Void = {
      $0.post(tap: .cghidEventTap)
    }
  ) {
    self.makeKeyEvent = makeKeyEvent
    self.postKeyEvent = postKeyEvent
  }

  func postKeyStroke(virtualKey: CGKeyCode, flags: CGEventFlags) -> Bool {
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
