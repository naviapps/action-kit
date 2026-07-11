/// A non-error reason why an action attempt could not run.
public enum ActionSkipReason: String, Codable, Hashable, CaseIterable, Sendable {
  /// No frontmost application was available for the requested action.
  case noFrontmostApplication = "no-frontmost-application"
  /// No focused window was available for the requested action.
  case noFocusedWindow = "no-focused-window"
}
