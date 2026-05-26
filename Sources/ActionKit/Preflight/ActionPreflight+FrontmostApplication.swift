extension ActionPreflight {
  static func frontmostApplicationPlan(for action: Action) -> ActionPlan? {
    switch action {
    case .hideFrontmostApplication:
      singleStepPlan(method: .hideFrontmostApplication)
    case .quitFrontmostApplication:
      singleStepPlan(method: .terminateFrontmostApplication)
    default:
      nil
    }
  }
}
