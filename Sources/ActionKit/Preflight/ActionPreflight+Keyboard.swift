extension ActionPreflight {
  static func keyboardPlan(for action: Action) -> ActionPlan? {
    switch action {
    case .keyboardShortcut(let value):
      singleStepPlan(method: .keyEventFromKeyboardShortcut(value))
    default:
      nil
    }
  }
}
