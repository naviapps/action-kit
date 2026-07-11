/// Canonical categories for execution failures.
public enum ActionErrorCode: String, Codable, Hashable, CaseIterable, Sendable {
  /// The action input was empty, malformed, or unsupported.
  case invalidInput = "invalid-input"
  /// A required macOS permission was denied or unavailable.
  case permissionDenied = "permission-denied"
  /// A requested URL, file path, application, or resource was not found.
  case notFound = "not-found"
  /// The system failed to open or launch a requested resource.
  case openFailed = "open-failed"
  /// AppleScript execution failed.
  case appleScriptFailed = "apple-script-failed"
  /// Screen capture execution failed.
  case screenCaptureFailed = "screen-capture-failed"
  /// An unexpected internal execution failure occurred.
  case internalError = "internal-error"
}
