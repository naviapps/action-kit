import Foundation
import WindowKit

/// Host-supplied input used to create an executable action from an action kind.
///
/// `ActionInput` carries values for action kinds whose ``ActionInputShape`` is not
/// ``ActionInputShape/none``. Use ``ActionKind/action()`` for input-free action kinds.
public enum ActionInput: Codable, Hashable, Sendable {
  /// Kind-specific text input.
  ///
  /// String values are trimmed by action creation and coding boundaries. Empty normalized strings
  /// are rejected by those boundaries.
  case string(String)
  /// Focused-window placement request.
  case windowPlacement(WindowPlacementRequest)
  /// Focused-window screen movement request.
  case windowMove(WindowMoveRequest)
}

extension ActionInput {
  /// The structural shape represented by this input.
  public var shape: ActionInputShape {
    switch self {
    case .string:
      .string
    case .windowPlacement:
      .windowPlacement
    case .windowMove:
      .windowMove
    }
  }

  package var normalized: ActionInput? {
    switch self {
    case let .string(value):
      guard let normalized = Self.normalizedString(value) else {
        return nil
      }
      return .string(normalized)
    case .windowPlacement, .windowMove:
      return self
    }
  }

  package static func normalizedString(_ value: String) -> String? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}
