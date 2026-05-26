import ActionKit
import ApplicationServices

extension ActionExecutor {
  func runAppleScript(
    _ source: String,
    requiresSystemEvents: Bool
  ) async -> ActionResult {
    guard await configuration.permissions.ensureAutomation() else {
      return .failure(.permissionDenied(.automation))
    }

    if requiresSystemEvents {
      guard await configuration.permissions.ensureAccessibility() else {
        return .failure(.permissionDenied(.accessibility))
      }

      guard await dependencies.systemEventsLauncher.ensureRunning() else {
        let actionError = ActionError.internalError("System Events is not running")
        configuration.log(.error, actionError.diagnosticMessage)
        return .failure(actionError)
      }
    }

    switch await dependencies.appleScriptExecutor.execute(source: source) {
    case .success:
      return .success
    case .failure(let error):
      if error.isAutomationPermissionDenied {
        let actionError = ActionError.automationPermissionDenied(
          appleScriptErrorNumber: error.appleScriptErrorNumber
        )
        configuration.log(.error, actionError.diagnosticMessage)
        return .failure(actionError)
      }

      let failureMessage = ActionExecutor.appleScriptFailureMessage(error)
      configuration.log(.error, failureMessage)
      return .failure(
        .appleScriptFailed(
          failureMessage,
          appleScriptErrorNumber: error.appleScriptErrorNumber
        )
      )
    }
  }

  private static func appleScriptFailureMessage(_ error: AppleScriptExecutionFailure) -> String {
    let message = error.message?.trimmingCharacters(in: .whitespacesAndNewlines)
    switch (message?.isEmpty == false ? message : nil, error.appleScriptErrorNumber) {
    case (.some(let message), .some(let appleScriptErrorNumber)):
      return "\(message) (AppleScript error number \(appleScriptErrorNumber))"
    case (.some(let message), .none):
      return message
    case (.none, .some(let appleScriptErrorNumber)):
      return "AppleScript execution failed with AppleScript error number \(appleScriptErrorNumber)"
    case (.none, .none):
      return "AppleScript execution failed"
    }
  }
}

private extension AppleScriptExecutionFailure {
  var isAutomationPermissionDenied: Bool {
    guard let appleScriptErrorNumber else {
      return false
    }
    return appleScriptErrorNumber == Int(errAEEventNotPermitted)
  }
}
