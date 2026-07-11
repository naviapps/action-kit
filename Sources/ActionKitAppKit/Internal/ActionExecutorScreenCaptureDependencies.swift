package protocol ScreenCaptureProcessRunning: Sendable {
  func run(arguments: [String]) async -> Result<Void, ScreenCaptureProcessFailure>
}

package struct ScreenCaptureProcessFailure: Error, Equatable, Sendable {
  package let terminationStatus: Int32?

  package init(terminationStatus: Int32? = nil) {
    self.terminationStatus = terminationStatus
  }
}

package protocol ScreenCaptureAccessChecking: Sendable {
  func hasAccess() -> Bool
}
