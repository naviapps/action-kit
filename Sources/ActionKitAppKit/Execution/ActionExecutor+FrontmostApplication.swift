import ActionKit

extension ActionExecutor {
  func executeHideFrontmostApplication() async -> ActionResult {
    let result = await dependencies.frontmostApplicationController.hideFrontmostApplication()
    return frontmostApplicationResult(
      result,
      failureMessage: "Failed to hide frontmost application"
    )
  }

  func executeTerminateFrontmostApplication() async -> ActionResult {
    let result = await dependencies.frontmostApplicationController.terminateFrontmostApplication()
    return frontmostApplicationResult(
      result,
      failureMessage: "Failed to terminate frontmost application"
    )
  }

  private func frontmostApplicationResult(
    _ result: FrontmostApplicationControlResult,
    failureMessage: String
  ) -> ActionResult {
    switch result {
    case .success:
      return .success
    case .noFrontmostApplication:
      return .skipped(.noFrontmostApplication)
    case .failed:
      let actionError = ActionError.internalError(failureMessage)
      configuration.log(.error, actionError.diagnosticMessage)
      return .failure(actionError)
    }
  }
}
