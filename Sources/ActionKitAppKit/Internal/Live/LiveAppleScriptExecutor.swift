import Foundation

struct LiveAppleScriptExecutor: AppleScriptExecuting {
  init() {}

  func execute(source: String) async -> Result<Void, AppleScriptExecutionFailure> {
    await Task.detached(priority: .userInitiated) {
      guard let script = NSAppleScript(source: source) else {
        return .failure(.init(appleScriptErrorNumber: nil))
      }

      var errorInfo: NSDictionary?
      script.executeAndReturnError(&errorInfo)
      if let errorInfo {
        return .failure(Self.failure(from: errorInfo))
      }
      return .success(())
    }.value
  }

  private static func failure(from errorInfo: NSDictionary) -> AppleScriptExecutionFailure {
    .init(
      appleScriptErrorNumber: errorNumber(in: errorInfo),
      message: errorMessage(in: errorInfo)
    )
  }

  private static func errorNumber(in errorInfo: NSDictionary) -> Int? {
    if let number = errorInfo[NSAppleScript.errorNumber] as? Int {
      return number
    }
    return (errorInfo[NSAppleScript.errorNumber] as? NSNumber)?.intValue
  }

  private static func errorMessage(in errorInfo: NSDictionary) -> String? {
    guard let message = errorInfo[NSAppleScript.errorMessage] as? String else {
      return nil
    }
    let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedMessage.isEmpty ? nil : trimmedMessage
  }
}
