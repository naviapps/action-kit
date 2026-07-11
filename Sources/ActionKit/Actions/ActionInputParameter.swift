/// Metadata describing an action kind's host-supplied input parameter.
///
/// Hosts can use this when building labels, dynamic forms, schema exporters, or tool surfaces.
public struct ActionInputParameter: Equatable, Hashable, Sendable {
  /// The parameter name a host UI, schema exporter, or tool surface can expose.
  public let name: String
  /// A short description of the accepted input value.
  public let description: String
  /// A representative input value.
  public let exampleInput: ActionInput

  /// Creates metadata describing an action kind's host-supplied input parameter.
  ///
  /// Returns `nil` when `name` or `description` is blank, or when `exampleInput` carries an
  /// invalid value.
  public init?(name: String, description: String, exampleInput: ActionInput) {
    guard
      let name = Self.normalizedMetadata(name),
      let description = Self.normalizedMetadata(description),
      let exampleInput = exampleInput.normalized
    else {
      return nil
    }

    self.name = name
    self.description = description
    self.exampleInput = exampleInput
  }

  init(canonicalName name: String, description: String, exampleInput: ActionInput) {
    self.name = name
    self.description = description
    self.exampleInput = exampleInput
  }
}

extension ActionInputParameter: Codable {
  private enum CodingKeys: String, CodingKey {
    case name
    case description
    case exampleInput
  }

  /// Decodes parameter metadata and rejects values that do not match parameter invariants.
  public init(from decoder: Decoder) throws {
    try decoder.rejectUnknownKeys(
      allowed: [CodingKeys.name, .description, .exampleInput],
      debugName: "ActionInputParameter"
    )
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let name = try container.decode(String.self, forKey: .name)
    let description = try container.decode(String.self, forKey: .description)
    let exampleInput = try container.decode(ActionInput.self, forKey: .exampleInput)

    guard
      let parameter = Self(name: name, description: description, exampleInput: exampleInput)
    else {
      throw DecodingError.dataCorrupted(
        .init(
          codingPath: decoder.codingPath,
          debugDescription: "Parameter metadata must be complete and valid."
        )
      )
    }

    self = parameter
  }

  /// Encodes normalized parameter metadata.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(name, forKey: .name)
    try container.encode(description, forKey: .description)
    try container.encode(exampleInput, forKey: .exampleInput)
  }
}

extension ActionInputParameter {
  private static func normalizedMetadata(_ value: String) -> String? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}
