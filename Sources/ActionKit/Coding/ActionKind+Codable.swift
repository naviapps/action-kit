extension ActionKind {
  /// Decodes an action kind from its stable semantic identifier.
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let identifier = try container.decode(String.self)
    guard let kind = Self(identifier: identifier) else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Unsupported action kind identifier: \(identifier)"
      )
    }
    self = kind
  }

  /// Encodes this action kind as its stable semantic identifier.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(identifier)
  }
}
