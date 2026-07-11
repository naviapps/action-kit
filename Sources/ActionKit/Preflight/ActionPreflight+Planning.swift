extension ActionPreflight {
  static func singleStepPlan(
    method: ActionMethod
  ) -> ActionPlan {
    .init(steps: [
      .init(method: method)
    ])
  }
}
