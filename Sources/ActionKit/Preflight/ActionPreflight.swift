/// Builds permission requirements and permission hints for actions.
public enum ActionPreflight {
  package static func plan(for action: Action) -> ActionPlan {
    editingPlan(for: action)
      ?? mediaPlan(for: action)
      ?? keyboardPlan(for: action)
      ?? frontmostApplicationPlan(for: action)
      ?? workspacePlan(for: action)
      ?? systemPlan(for: action)
      ?? windowingPlan(for: action)
      ?? .init(steps: [])
  }

  package static func plan(forKind kind: ActionKind) -> ActionPlan {
    permissionSampleAction(forKind: kind).map(plan(for:)) ?? .init(steps: [])
  }

  /// Returns the aggregate permission requirements for an action.
  ///
  /// - Parameter action: The executable action to inspect.
  /// - Returns: The permissions required by the action's primary and fallback paths.
  public static func permissions(for action: Action) -> ActionPermissionSet {
    plan(for: action).permissionRequirements
  }

  /// Returns the input-independent permission requirements for an action kind.
  ///
  /// - Parameter kind: The action kind to inspect before host input is available.
  /// - Returns: The input-independent permissions required by the action kind.
  public static func permissions(forKind kind: ActionKind) -> ActionPermissionSet {
    plan(forKind: kind).permissionRequirements
  }

  private static func permissionSampleAction(forKind kind: ActionKind) -> Action? {
    if let exampleInput = kind.inputDescriptor.exampleInput {
      return kind.action(input: exampleInput)
    }
    return kind.action()
  }
}
