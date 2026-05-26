extension ActionPreflight {
  static func workspacePlan(for action: Action) -> ActionPlan? {
    switch action {
    case .openURL(let value):
      singleStepPlan(method: .openURL(value))
    case .openFolder(let value):
      singleStepPlan(method: .openFolder(value))
    case .launchApplication(let value):
      singleStepPlan(method: .launchApplication(value))
    case .runShortcut(let value):
      singleStepPlan(method: .runShortcut(value))
    default:
      nil
    }
  }
}
