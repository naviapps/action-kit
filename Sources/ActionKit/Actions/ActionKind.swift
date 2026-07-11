/// A catalog entry for a supported action.
///
/// Use action kinds for pickers, registries, and tool surfaces before host-supplied input is
/// available. Use ``identifier`` or ``ActionCodec`` payloads for persistence and IPC instead of
/// treating enum case names as protocol strings.
public enum ActionKind: Codable, Hashable, CaseIterable, Sendable {
  /// Copies the current selection.
  case copy
  /// Pastes from the clipboard.
  case paste
  /// Cuts the current selection.
  case cut
  /// Undoes the last edit action.
  case undo
  /// Redoes the last undone edit action.
  case redo

  /// Hides the frontmost application.
  case hideFrontmostApplication
  /// Quits the frontmost application.
  case quitFrontmostApplication

  /// Raises the output volume.
  case volumeUp
  /// Lowers the output volume.
  case volumeDown
  /// Toggles output mute.
  case volumeMute
  /// Toggles media playback.
  case mediaPlayPause
  /// Skips to the next media item.
  case mediaNext
  /// Skips to the previous media item.
  case mediaPrevious

  /// Sends a host-supplied keyboard shortcut.
  case keyboardShortcut
  /// Opens a host-supplied URL string.
  case openURL
  /// Launches a host-supplied application name, bundle identifier, or .app bundle path.
  case launchApplication
  /// Runs a host-supplied Shortcuts shortcut name.
  case runShortcut
  /// Opens a host-supplied folder path.
  case openFolder

  /// Opens Mission Control.
  case missionControl
  /// Shows the desktop.
  case showDesktop
  /// Locks the current user session.
  case lockScreen
  /// Puts the Mac to sleep.
  case sleepMac
  /// Moves to the next Mission Control space.
  case missionControlNextSpace
  /// Moves to the previous Mission Control space.
  case missionControlPreviousSpace
  /// Opens App Expose for the frontmost application.
  case missionControlAppExpose
  /// Raises display brightness.
  case brightnessUp
  /// Lowers display brightness.
  case brightnessDown
  /// Toggles the system appearance.
  case toggleAppearance
  /// Shows Notification Center.
  case showNotificationCenter
  /// Captures the full screen.
  case captureScreenFull
  /// Captures a user-selected screen region.
  case captureScreenSelection
  /// Captures a user-selected window.
  case captureScreenWindow

  /// Places the focused window using an explicit placement request.
  case windowPlacement
  /// Moves the focused window using an explicit screen movement request.
  case windowMove
}
