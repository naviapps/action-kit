/// A reason code for a permission requirement.
public enum ActionPermissionReason: String, Sendable, Codable, Hashable, CaseIterable {
  /// The action uses Accessibility in a general way.
  case accessibility
  /// The action sends key events through Accessibility.
  case accessibilityKeyEvent = "accessibility-key-event"
  /// The action controls the focused window through Accessibility.
  case accessibilityWindowing = "accessibility-windowing"
  /// The action sends Apple Events through AppleScript.
  case automationAppleEvents = "automation-apple-events"
  /// The action captures screen contents.
  case screenRecordingCapture = "screen-recording-capture"
}
