import ActionKit

extension ActionExecutor {
  func invalidInputResult(_ message: String) -> ActionResult {
    failureResult(.invalidInput(message), logLevel: .warning)
  }

  func permissionDeniedResult(_ permission: ActionPermission) -> ActionResult {
    failureResult(.permissionDenied(permission), logLevel: .warning)
  }

  func notFoundResult(_ message: String) -> ActionResult {
    failureResult(.notFound(message), logLevel: .error)
  }

  func openFailedResult(_ message: String) -> ActionResult {
    failureResult(.openFailed(message), logLevel: .error)
  }

  func internalErrorResult(_ message: String) -> ActionResult {
    failureResult(.internalError(message), logLevel: .error)
  }

  func failureResult(
    _ error: ActionError,
    logLevel: ActionExecutorConfiguration.LogLevel
  ) -> ActionResult {
    configuration.log(logLevel, error.diagnosticMessage)
    return .failure(error)
  }
}
