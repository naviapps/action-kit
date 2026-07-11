import ApplicationServices

struct LiveKeyEventPoster: KeyEventPosting {
  private let keyStrokePoster: KeyStrokeEventPoster

  init() {
    keyStrokePoster = KeyStrokeEventPoster(postKeyEvent: { event in
      event.post(tap: .cghidEventTap)
    })
  }

  func postKeyStroke(virtualKey: CGKeyCode, flags: CGEventFlags) -> Bool {
    keyStrokePoster.postKeyStroke(virtualKey: virtualKey, flags: flags)
  }
}
