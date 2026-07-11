extension ActionPreflight {
  static func editingPlan(for action: Action) -> ActionPlan? {
    guard let method = editingKeyEvent(for: action) else {
      return nil
    }

    return singleStepPlan(method: method)
  }

  private static func editingKeyEvent(for action: Action) -> ActionMethod? {
    switch action {
    case .copy:
      .keyEvent(virtualKeyCode: VirtualKeyCode.copy, modifiers: [.command])
    case .paste:
      .keyEvent(virtualKeyCode: VirtualKeyCode.paste, modifiers: [.command])
    case .cut:
      .keyEvent(virtualKeyCode: VirtualKeyCode.cut, modifiers: [.command])
    case .undo:
      .keyEvent(virtualKeyCode: VirtualKeyCode.undo, modifiers: [.command])
    case .redo:
      .keyEvent(virtualKeyCode: VirtualKeyCode.undo, modifiers: [.command, .shift])
    default:
      nil
    }
  }
}
