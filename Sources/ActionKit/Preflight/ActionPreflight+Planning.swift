extension ActionPreflight {
  static func singleStepPlan(
    method: ActionMethod,
    requiredPermissions: [ActionPermission] = []
  ) -> ActionPlan {
    .init(steps: [
      .init(method: method, requiredPermissions: Set(requiredPermissions))
    ])
  }
}
