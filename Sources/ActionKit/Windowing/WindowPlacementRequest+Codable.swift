import CoreGraphics

extension WindowPlacementRequest: Codable {
  private enum CodingKeys: String, CodingKey {
    case placement
    case screen
    case area
    case inset
  }

  /// Decodes a placement request and applies the same inset normalization as direct creation.
  public init(from decoder: Decoder) throws {
    try decoder.rejectUnknownKeys(
      allowed: [
        CodingKeys.placement,
        .screen,
        .area,
        .inset,
      ],
      debugName: "WindowPlacementRequest"
    )
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      placement: try container.decode(ActionWindowPlacement.self, forKey: .placement),
      screen: try container.decodeIfPresentRejectingNull(
        ActionWindowScreenTarget.self,
        forKey: .screen
      ) ?? .containingWindow,
      area: try container.decodeIfPresentRejectingNull(
        ActionWindowScreenArea.self,
        forKey: .area
      ) ?? .visible,
      inset: try container.decodeIfPresentRejectingNull(CGFloat.self, forKey: .inset) ?? 0
    )
  }

  /// Encodes a placement request using canonical public field names.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(placement, forKey: .placement)
    try container.encode(screen, forKey: .screen)
    try container.encode(area, forKey: .area)
    try container.encode(inset, forKey: .inset)
  }
}
