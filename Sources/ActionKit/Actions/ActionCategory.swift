/// A grouping for action catalogs.
///
/// Use categories to group and filter action kinds. Hosts remain responsible for display labels,
/// ordering, and localization.
public enum ActionCategory: String, Codable, Hashable, CaseIterable, Sendable {
  /// Editing actions such as copy, paste, undo, and redo.
  case editing
  /// Actions that affect the frontmost application.
  case frontmostApplication = "frontmost-application"
  /// Media and volume key actions.
  case media
  /// Keyboard shortcut actions.
  case keyboard
  /// Workspace actions such as opening URLs, folders, apps, and running shortcuts.
  case workspace
  /// System-level actions such as Mission Control, brightness, and screen capture.
  case system
  /// Focused-window placement and movement actions.
  case window
}
