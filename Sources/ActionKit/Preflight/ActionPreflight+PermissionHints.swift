extension ActionPreflight {
  /// Returns permission hints for an action.
  ///
  /// - Parameter action: The executable action to inspect.
  /// - Returns: Permission hints ordered by execution path.
  public static func permissionHints(for action: Action) -> [ActionPermissionHint] {
    permissionHints(for: plan(for: action))
  }

  /// Returns input-independent permission hints for an action kind.
  ///
  /// - Parameter kind: The action kind to inspect before host input is available.
  /// - Returns: Input-independent permission hints ordered by execution path.
  public static func permissionHints(forKind kind: ActionKind) -> [ActionPermissionHint] {
    permissionHints(for: plan(forKind: kind))
  }

  static func permissionHints(for plan: ActionPlan) -> [ActionPermissionHint] {
    var hints: [ActionPermissionHint] = []
    var seenPermissions: Set<ActionPermission> = []

    for step in plan.steps {
      for permission in step.requiredPermissions.canonicalCodableOrder {
        guard seenPermissions.insert(permission).inserted else {
          continue
        }
        hints.append(permissionHint(for: permission, method: step.method))
      }
    }

    return hints
  }

  private static func permissionHint(
    for permission: ActionPermission,
    method: ActionMethod
  ) -> ActionPermissionHint {
    switch permission {
    case .accessibility:
      return ActionPermissionHint(
        permission: permission,
        reason: accessibilityReason(for: method)
      )
    case .automation:
      return ActionPermissionHint(
        permission: permission,
        reason: .automationAppleEvents
      )
    case .screenRecording:
      return ActionPermissionHint(
        permission: permission,
        reason: .screenRecordingCapture
      )
    }
  }

  private static func accessibilityReason(for method: ActionMethod) -> ActionPermissionReason {
    switch method {
    case .keyEvent, .keyEventFromKeyboardShortcut:
      return .accessibilityKeyEvent
    case .windowing:
      return .accessibilityWindowing
    case .appleScript, .openURL, .openFolder, .launchApplication, .runShortcut, .screenCapture,
      .hideFrontmostApplication, .terminateFrontmostApplication:
      return .accessibility
    }
  }
}
