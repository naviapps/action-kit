package struct ActionStep: Sendable, Equatable, Hashable {
  package let method: ActionMethod
  package let isFallback: Bool

  package var requiredPermissions: Set<ActionPermission> {
    method.requiredPermissions
  }

  package init(
    method: ActionMethod,
    isFallback: Bool = false
  ) {
    self.method = method
    self.isFallback = isFallback
  }
}

package struct ActionPlan: Sendable, Equatable, Hashable {
  package let steps: [ActionStep]

  package init(steps: [ActionStep]) {
    self.steps = steps
  }

  package var permissionRequirements: ActionPermissionSet {
    var primary: Set<ActionPermission> = []
    var fallback: Set<ActionPermission> = []

    for step in steps {
      if step.isFallback {
        fallback.formUnion(step.requiredPermissions)
      } else {
        primary.formUnion(step.requiredPermissions)
      }
    }

    return .init(primary: primary, fallback: fallback)
  }
}
