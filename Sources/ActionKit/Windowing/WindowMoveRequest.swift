import WindowKit

/// A request to move the focused window between screens.
public struct WindowMoveRequest: Sendable, Equatable, Hashable {
  /// The direction of screen movement.
  public let direction: WindowScreenCycleDirection
  /// Whether to preserve the window's relative position on the destination screen.
  public let preservesRelativePosition: Bool

  /// Creates a focused-window screen movement request.
  ///
  /// - Parameters:
  ///   - direction: The direction of screen movement.
  ///   - preservesRelativePosition: Whether to preserve the window's relative position.
  public init(
    direction: WindowScreenCycleDirection,
    preservesRelativePosition: Bool = true
  ) {
    self.direction = direction
    self.preservesRelativePosition = preservesRelativePosition
  }
}

extension WindowMoveRequest: Codable {
  private enum CodingKeys: String, CodingKey {
    case direction
    case preservesRelativePosition
  }

  private enum DirectionValue: String, Codable {
    case next
    case previous

    var direction: WindowScreenCycleDirection {
      switch self {
      case .next: .next
      case .previous: .previous
      }
    }

    init(_ direction: WindowScreenCycleDirection) {
      switch direction {
      case .next:
        self = .next
      case .previous:
        self = .previous
      }
    }
  }

  /// Decodes a focused-window screen movement request from stable public field names.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      direction: try container.decode(DirectionValue.self, forKey: .direction).direction,
      preservesRelativePosition: try container.contains(.preservesRelativePosition)
        ? container.decode(Bool.self, forKey: .preservesRelativePosition)
        : true
    )
  }

  /// Encodes a focused-window screen movement request using stable public field names.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(DirectionValue(direction), forKey: .direction)
    try container.encode(preservesRelativePosition, forKey: .preservesRelativePosition)
  }
}
