import CoreGraphics

/// ActionKit-owned screen selection rule for focused-window actions.
public enum ActionWindowScreenTarget: Equatable, Hashable, Sendable {
  case main
  case containingWindow
  case point(CGPoint)
  case displayIdentifier(CGDirectDisplayID)
  case orderedIndex(Int)
}

extension ActionWindowScreenTarget {
  var normalized: Self {
    switch self {
    case .main, .containingWindow, .displayIdentifier:
      self
    case .point(let point):
      .point(
        CGPoint(
          x: point.x.isFinite ? point.x : 0,
          y: point.y.isFinite ? point.y : 0
        )
      )
    case .orderedIndex(let index):
      .orderedIndex(max(0, index))
    }
  }
}

extension ActionWindowScreenTarget: Codable {
  private enum CodingKeys: String, CodingKey {
    case kind
    case x
    case y
    case displayIdentifier
    case orderedIndex
  }

  private enum Kind: String, Codable {
    case main
    case containingWindow = "containing-window"
    case point
    case displayIdentifier = "display-identifier"
    case orderedIndex = "ordered-index"
  }

  /// Decodes a screen target from ActionKit's canonical payload shape.
  public init(from decoder: Decoder) throws {
    try decoder.rejectUnknownKeys(
      allowed: [
        CodingKeys.kind,
        .x,
        .y,
        .displayIdentifier,
        .orderedIndex,
      ],
      debugName: "ActionWindowScreenTarget"
    )
    let container = try decoder.container(keyedBy: CodingKeys.self)

    let decoded: Self
    switch try container.decode(Kind.self, forKey: .kind) {
    case .main:
      try Self.rejectAssociatedFields(in: container)
      decoded = .main
    case .containingWindow:
      try Self.rejectAssociatedFields(in: container)
      decoded = .containingWindow
    case .point:
      try Self.rejectFields([.displayIdentifier, .orderedIndex], in: container)
      decoded = .point(
        CGPoint(
          x: try container.decode(CGFloat.self, forKey: .x),
          y: try container.decode(CGFloat.self, forKey: .y)
        )
      )
    case .displayIdentifier:
      try Self.rejectFields([.x, .y, .orderedIndex], in: container)
      decoded = .displayIdentifier(
        try container.decode(CGDirectDisplayID.self, forKey: .displayIdentifier))
    case .orderedIndex:
      try Self.rejectFields([.x, .y, .displayIdentifier], in: container)
      decoded = .orderedIndex(try container.decode(Int.self, forKey: .orderedIndex))
    }
    self = decoded.normalized
  }

  /// Encodes the screen target using ActionKit's canonical payload shape.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch normalized {
    case .main:
      try container.encode(Kind.main, forKey: .kind)
    case .containingWindow:
      try container.encode(Kind.containingWindow, forKey: .kind)
    case let .point(point):
      try container.encode(Kind.point, forKey: .kind)
      try container.encode(point.x, forKey: .x)
      try container.encode(point.y, forKey: .y)
    case let .displayIdentifier(displayIdentifier):
      try container.encode(Kind.displayIdentifier, forKey: .kind)
      try container.encode(displayIdentifier, forKey: .displayIdentifier)
    case let .orderedIndex(orderedIndex):
      try container.encode(Kind.orderedIndex, forKey: .kind)
      try container.encode(orderedIndex, forKey: .orderedIndex)
    }
  }

  private static func rejectAssociatedFields(
    in container: KeyedDecodingContainer<CodingKeys>
  ) throws {
    try rejectFields([.x, .y, .displayIdentifier, .orderedIndex], in: container)
  }

  private static func rejectFields(
    _ keys: [CodingKeys],
    in container: KeyedDecodingContainer<CodingKeys>
  ) throws {
    for key in keys where container.contains(key) {
      throw DecodingError.dataCorruptedError(
        forKey: key,
        in: container,
        debugDescription: "\(key.stringValue) is not valid for this screen target kind."
      )
    }
  }
}
