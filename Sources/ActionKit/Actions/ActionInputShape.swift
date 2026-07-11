/// The structural shape of host-supplied input required by an action kind.
///
/// Use this as a canonical discriminator for catalog metadata, schema export, and serialized action
/// payloads. The ``none`` case describes input-free action kinds; it is not represented by
/// ``ActionInput``.
public enum ActionInputShape: String, Codable, Hashable, CaseIterable, Sendable {
  /// No host-supplied input is required.
  case none
  /// Kind-specific text input is required.
  case string
  /// A focused-window placement request is required.
  case windowPlacement = "window-placement"
  /// A focused-window screen movement request is required.
  case windowMove = "window-move"
}
