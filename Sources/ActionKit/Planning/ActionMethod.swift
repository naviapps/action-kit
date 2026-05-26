package enum ActionMethod: Sendable, Equatable, Hashable {
  case keyEvent(ActionKeyStroke)
  case keyEventFromKeyboardShortcut(String)
  case appleScript(source: String, requiresSystemEvents: Bool)
  case openURL(String)
  case openFolder(String)
  case launchApplication(String)
  case runShortcut(String)
  case hideFrontmostApplication
  case terminateFrontmostApplication
  case screenCapture(arguments: [String])
  case windowing(WindowingExecution)
}

package enum WindowingExecution: Sendable, Equatable, Hashable {
  case placeFocusedWindow(WindowPlacementRequest)
  case moveFocusedWindow(WindowMoveRequest)
}

package struct ActionModifiers: OptionSet, Sendable, Equatable, Hashable {
  package let rawValue: UInt16

  package init(rawValue: UInt16) {
    self.rawValue = rawValue
  }

  package static let command = Self(rawValue: 1 << 0)
  package static let shift = Self(rawValue: 1 << 1)
  package static let option = Self(rawValue: 1 << 2)
  package static let control = Self(rawValue: 1 << 3)
  package static let function = Self(rawValue: 1 << 4)
}

package struct ActionKeyStroke: Sendable, Equatable, Hashable {
  package let virtualKeyCode: UInt16
  package let modifiers: ActionModifiers

  package init(virtualKeyCode: UInt16, modifiers: ActionModifiers = []) {
    self.virtualKeyCode = virtualKeyCode
    self.modifiers = modifiers
  }
}

extension ActionMethod {
  package static func keyEvent(virtualKeyCode: UInt16, modifiers: ActionModifiers = []) -> Self {
    .keyEvent(.init(virtualKeyCode: virtualKeyCode, modifiers: modifiers))
  }
}
