extension ActionInput {
  private enum CodingKeys: String, CodingKey {
    case shape
    case value
  }

  /// Decodes an action input from its structural shape and value payload.
  public init(from decoder: Decoder) throws {
    try decoder.rejectUnknownKeys(allowed: [CodingKeys.shape, .value], debugName: "ActionInput")
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let shape = try container.decode(ActionInputShape.self, forKey: .shape)

    switch shape {
    case .none:
      throw DecodingError.dataCorruptedError(
        forKey: .shape,
        in: container,
        debugDescription: "ActionInput cannot represent an input-free action shape."
      )
    case .string:
      let string = try container.decode(String.self, forKey: .value)
      guard let normalized = Self.normalizedString(string) else {
        throw DecodingError.dataCorruptedError(
          forKey: .value,
          in: container,
          debugDescription: "String action input must not be empty."
        )
      }
      self = .string(normalized)
    case .windowPlacement:
      self = try .windowPlacement(container.decode(WindowPlacementRequest.self, forKey: .value))
    case .windowMove:
      self = try .windowMove(container.decode(WindowMoveRequest.self, forKey: .value))
    }
  }

  /// Encodes an action input as its structural shape and value payload.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
    case .string(let string):
      guard let normalized = Self.normalizedString(string) else {
        throw EncodingError.invalidValue(
          self,
          .init(
            codingPath: container.codingPath + [CodingKeys.value],
            debugDescription: "String action input must not be empty."
          )
        )
      }
      try container.encode(ActionInputShape.string, forKey: .shape)
      try container.encode(normalized, forKey: .value)
    case .windowPlacement(let request):
      try container.encode(ActionInputShape.windowPlacement, forKey: .shape)
      try container.encode(request, forKey: .value)
    case .windowMove(let request):
      try container.encode(ActionInputShape.windowMove, forKey: .shape)
      try container.encode(request, forKey: .value)
    }
  }
}
