/// A macOS privacy permission an action may require.
public enum ActionPermission: String, Codable, Hashable, CaseIterable, Sendable {
  /// Accessibility permission for key events and focused-window control.
  case accessibility
  /// Automation permission for Apple Events sent by AppleScript-backed actions.
  case automation
  /// Screen Recording permission for screen capture actions.
  case screenRecording = "screen-recording"
}
