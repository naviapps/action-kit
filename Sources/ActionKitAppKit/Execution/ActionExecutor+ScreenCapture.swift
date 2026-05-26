import ActionKit

extension ActionExecutor {
  func executeScreenCapture(arguments: [String]) async -> ActionResult {
    guard dependencies.screenCaptureAccessChecker.hasAccess() else {
      let actionError = ActionError.permissionDenied(.screenRecording)
      configuration.log(.warning, actionError.diagnosticMessage)
      await configuration.permissions.onScreenRecordingRequired()
      return .failure(actionError)
    }

    switch await dependencies.screenCaptureProcessRunner.run(arguments: arguments) {
    case .success:
      return .success
    case .failure(let error):
      let actionError = ActionError.screenCaptureFailed(
        Self.screenCaptureFailureMessage(terminationStatus: error.terminationStatus)
      )
      configuration.log(.error, actionError.diagnosticMessage)
      return .failure(actionError)
    }
  }

  private static func screenCaptureFailureMessage(terminationStatus: Int32?) -> String {
    guard let terminationStatus else { return "Screen capture failed" }
    return "Screen capture failed with termination status \(terminationStatus)"
  }
}
