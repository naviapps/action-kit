extension Action {
  private enum CodingKeys: String, CodingKey {
    case kind
    case input
  }

  /// Decodes an action from its kind and optional input.
  public init(from decoder: Decoder) throws {
    try decoder.rejectUnknownKeys(allowed: [CodingKeys.kind, .input], debugName: "Action")
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let kind = try container.decode(ActionKind.self, forKey: .kind)

    switch kind.inputDescriptor.shape {
    case .none:
      self = try Self.decodeInputFreeAction(kind, container: container)
    case .string:
      let string = try container.decode(String.self, forKey: .input)
      self = try Self.decodeAction(kind, input: .string(string), container: container)
    case .windowPlacement:
      let request = try container.decode(WindowPlacementRequest.self, forKey: .input)
      self = try Self.decodeAction(kind, input: .windowPlacement(request), container: container)
    case .windowMove:
      let request = try container.decode(WindowMoveRequest.self, forKey: .input)
      self = try Self.decodeAction(kind, input: .windowMove(request), container: container)
    }
  }

  /// Encodes an action as its kind and optional input.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(kind, forKey: .kind)
    let inputCodingPath = encoder.codingPath + [CodingKeys.input]
    try encodeActionInput(to: &container, codingPath: inputCodingPath)
  }

  private func encodeActionInput(
    to container: inout KeyedEncodingContainer<CodingKeys>,
    codingPath: [CodingKey]
  ) throws {
    guard let input else {
      if !kind.inputDescriptor.requiresInput {
        return
      }

      throw EncodingError.invalidValue(
        self,
        .init(
          codingPath: codingPath,
          debugDescription: "Action kind \(kind.identifier) requires non-empty input."
        )
      )
    }

    switch input {
    case .string(let value):
      guard let normalized = ActionInput.normalizedString(value) else {
        throw EncodingError.invalidValue(
          self,
          .init(
            codingPath: codingPath,
            debugDescription: "Action kind \(kind.identifier) requires non-empty string input."
          )
        )
      }
      try container.encode(normalized, forKey: .input)
    case .windowPlacement(let request):
      try container.encode(request, forKey: .input)
    case .windowMove(let request):
      try container.encode(request, forKey: .input)
    }
  }
}

extension Action {
  private static func decodeInputFreeAction(
    _ kind: ActionKind,
    container: KeyedDecodingContainer<CodingKeys>
  ) throws -> Action {
    guard !container.contains(.input) else {
      throw DecodingError.dataCorruptedError(
        forKey: .input,
        in: container,
        debugDescription: "Action kind \(kind.identifier) does not accept input."
      )
    }
    guard let action = kind.makeAction() else {
      throw DecodingError.dataCorruptedError(
        forKey: .kind,
        in: container,
        debugDescription: "Action kind \(kind.identifier) is not an input-free action."
      )
    }
    return action
  }

  private static func decodeAction(
    _ kind: ActionKind,
    input: ActionInput,
    container: KeyedDecodingContainer<CodingKeys>
  ) throws -> Action {
    guard let action = kind.makeAction(input: input) else {
      let description = "Action kind \(kind.identifier) requires valid input."
      throw DecodingError.dataCorruptedError(
        forKey: .input,
        in: container,
        debugDescription: description
      )
    }
    return action
  }
}
