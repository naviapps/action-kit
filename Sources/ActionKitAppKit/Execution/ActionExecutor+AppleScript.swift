import ActionKit
import ApplicationServices

extension ActionExecutor {
  func runAppleScript(
    _ source: String,
    launchesSystemEvents: Bool
  ) async -> ActionResult {
    if launchesSystemEvents {
      guard await dependencies.systemEventsLauncher.ensureRunning() else {
        return internalErrorResult("System Events is not running")
      }
    }

    switch await dependencies.appleScriptExecutor.execute(source: source) {
    case .success:
      return .success
    case .failure(let error):
      if error.isAutomationPermissionDenied {
        return failureResult(
          .automationPermissionDenied(appleScriptErrorNumber: error.appleScriptErrorNumber),
          logLevel: .error
        )
      }

      let failureMessage = ActionExecutor.appleScriptFailureMessage(error)
      return failureResult(
        .appleScriptFailed(
          failureMessage,
          appleScriptErrorNumber: error.appleScriptErrorNumber
        ),
        logLevel: .error
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
