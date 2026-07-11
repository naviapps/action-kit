import ActionKit

/// Executes actions using live macOS integrations.
public actor ActionExecutor {
  let configuration: ActionExecutorConfiguration
  let dependencies: ActionExecutorDependencies

  /// Creates an executor with live dependencies.
  ///
  /// - Parameter configuration: Host-provided execution hooks and diagnostics.
  public init(configuration: ActionExecutorConfiguration = .init()) {
    self.init(configuration: configuration, dependencies: .live)
  }

  /// Executes an action.
  ///
  /// - Parameter action: The action to execute.
  /// - Returns: The ordered execution outcome.
  public func execute(_ action: Action) async -> ActionOutcome {
    await execute(plan: ActionPreflight.plan(for: action))
  }

  package init(
    configuration: ActionExecutorConfiguration = .init(),
    dependencies: ActionExecutorDependencies
  ) {
    self.configuration = configuration
    self.dependencies = dependencies
  }

  package func execute(plan: ActionPlan) async -> ActionOutcome {
    var observedAutomationDenied = false
    var automationDeniedAppleScriptErrorNumber: Int?
    var lastFailure: ActionError?
    var attempts: [ActionAttempt] = []
    let clock = ContinuousClock()

    for step in plan.steps {
      let start = clock.now
      let attemptResult: ActionResult
      if let validationFailure = validationFailure(for: step.method) {
        attemptResult = validationFailure
      } else if let permissionFailure = await permissionFailure(for: step.method) {
        attemptResult = permissionFailure
      } else {
        attemptResult = await execute(step.method)
      }
      let duration = clock.now - start
      attempts.append(.init(step: step, result: attemptResult, duration: duration))

      switch attemptResult {
      case .success:
        return .init(attempts: attempts)
      case .skipped:
        continue
      case .failure(let error):
        if error.code == .permissionDenied, error.permission == .automation {
          observedAutomationDenied = true
          if let appleScriptErrorNumber = error.appleScriptErrorNumber {
            automationDeniedAppleScriptErrorNumber = appleScriptErrorNumber
          }
        }
        lastFailure = error
        continue
      }
    }

    guard let lastFailure, observedAutomationDenied,
      !(lastFailure.code == .permissionDenied && lastFailure.permission == .accessibility)
    else {
      return .init(attempts: attempts)
    }

    await configuration.permissions.onAutomationDenied(automationDeniedAppleScriptErrorNumber)
    return .init(attempts: attempts)
  }

  private func execute(_ method: ActionMethod) async -> ActionResult {
    switch method {
    case .keyEvent(let event):
      return await executeKeyEvent(event)
    case .keyEventFromKeyboardShortcut(let shortcut):
      return await executeKeyboardShortcut(shortcut)
    case .appleScript(let source, let launchesSystemEvents, _):
      return await runAppleScript(source, launchesSystemEvents: launchesSystemEvents)
    case .openURL(let value):
      return await executeOpenURL(value)
    case .openFolder(let value):
      return await executeOpenFolder(value)
    case .launchApplication(let value):
      return await executeLaunchApplication(value)
    case .runShortcut(let value):
      return await executeRunShortcut(value)
    case .hideFrontmostApplication:
      return await executeHideFrontmostApplication()
    case .terminateFrontmostApplication:
      return await executeTerminateFrontmostApplication()
    case .screenCapture(let arguments):
      return await executeScreenCapture(arguments: arguments)
    case .windowing(let execution):
      return await executeWindowing(execution)
    }
  }

  private func validationFailure(for method: ActionMethod) -> ActionResult? {
    guard case .keyEventFromKeyboardShortcut(let shortcut) = method else {
      return nil
    }
    guard KeyboardShortcutParser.parse(shortcut) == nil else {
      return nil
    }
    return invalidInputResult("Failed to parse keyboard shortcut")
  }

  private func permissionFailure(for method: ActionMethod) async -> ActionResult? {
    for permission in method.requiredPermissions.canonicalCodableOrder {
      let isReady: Bool
      switch permission {
      case .accessibility:
        isReady = await configuration.permissions.ensureAccessibility()
      case .automation:
        isReady = await configuration.permissions.ensureAutomation()
      case .screenRecording:
        isReady = dependencies.screenCaptureAccessChecker.hasAccess()
      }

      guard !isReady else { continue }
      let result = permissionDeniedResult(permission)
      if permission == .screenRecording {
        await configuration.permissions.onScreenRecordingRequired()
      }
      return result
    }

    return nil
  }
}
