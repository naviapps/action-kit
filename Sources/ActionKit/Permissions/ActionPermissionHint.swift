/// A permission requirement and the action-specific reason it is needed.
public struct ActionPermissionHint: Sendable, Equatable, Hashable, Codable {
  /// The required permission.
  public let permission: ActionPermission
  /// The stable reason code a host app can map to user-facing copy.
  public let reason: ActionPermissionReason

  /// Creates a permission hint.
  ///
  /// - Parameters:
  ///   - permission: The required macOS privacy permission.
  ///   - reason: The action-specific reason the permission is needed.
  public init(permission: ActionPermission, reason: ActionPermissionReason) {
    self.permission = permission
    self.reason = reason
  }
}

/// A stable reason code for a permission requirement.
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
