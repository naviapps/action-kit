import ActionKit

extension ActionExecutor {
  func executeScreenCapture(arguments: [String]) async -> ActionResult {
    switch await dependencies.screenCaptureProcessRunner.run(arguments: arguments) {
    case .success:
      return .success
    case .failure(let error):
      return failureResult(
        .screenCaptureFailed(
          Self.screenCaptureFailureMessage(terminationStatus: error.terminationStatus)
        ),
        logLevel: .error
      )
    }
  }

  private static func screenCaptureFailureMessage(terminationStatus: Int32?) -> String {
    guard let terminationStatus else { return "Screen capture failed" }
    return "Screen capture failed with termination status \(terminationStatus)"
  }
}
