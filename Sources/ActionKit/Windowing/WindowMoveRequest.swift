/// A request to move the focused window between screens.
public struct WindowMoveRequest: Sendable, Equatable, Hashable {
  /// The direction of screen movement.
  public let direction: ActionWindowScreenCycleDirection
  /// Whether to preserve the window's relative position on the destination screen.
  public let preservesRelativePosition: Bool

  /// Creates a focused-window screen movement request.
  ///
  /// - Parameters:
  ///   - direction: The direction of screen movement.
  ///   - preservesRelativePosition: Whether to preserve the window's relative position.
  public init(
    direction: ActionWindowScreenCycleDirection,
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

  /// Decodes a focused-window screen movement request from canonical public field names.
  public init(from decoder: Decoder) throws {
    try decoder.rejectUnknownKeys(
      allowed: [
        CodingKeys.direction,
        .preservesRelativePosition,
      ],
      debugName: "WindowMoveRequest"
    )
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      direction: try container.decode(ActionWindowScreenCycleDirection.self, forKey: .direction),
      preservesRelativePosition: try container.decodeIfPresentRejectingNull(
        Bool.self,
        forKey: .preservesRelativePosition
      ) ?? true
    )
  }

  /// Encodes a focused-window screen movement request using canonical public field names.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(direction, forKey: .direction)
    try container.encode(preservesRelativePosition, forKey: .preservesRelativePosition)
  }
}
