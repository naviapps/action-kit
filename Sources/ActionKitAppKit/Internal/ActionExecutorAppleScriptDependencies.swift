package protocol AppleScriptExecuting: Sendable {
  func execute(source: String) async -> Result<Void, AppleScriptExecutionFailure>
}

package struct AppleScriptExecutionFailure: Error, Equatable, Sendable {
  package let appleScriptErrorNumber: Int?
  package let message: String?

  package init(appleScriptErrorNumber: Int? = nil, message: String? = nil) {
    self.appleScriptErrorNumber = appleScriptErrorNumber
    self.message = message
  }
}

package protocol SystemEventsLaunching: Sendable {
  func ensureRunning() async -> Bool
}
