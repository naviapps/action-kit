/// The result of one action attempt or a whole action.
public enum ActionResult: Codable, Sendable, Equatable, Hashable {
  /// The action attempt completed successfully.
  case success
  /// The action attempt could not run for a non-error reason.
  case skipped(ActionSkipReason)
  /// The action attempt failed with a structured error.
  case failure(ActionError)
}

extension ActionResult {
  private enum CodingKeys: String, CodingKey {
    case status
    case skipReason
    case error
  }

  private enum Status: String, Codable {
    case success
    case skipped
    case failure
  }

  /// Decodes an action result from its canonical status payload.
  public init(from decoder: Decoder) throws {
    try decoder.rejectUnknownKeys(
      allowed: [CodingKeys.status, .skipReason, .error],
      debugName: "ActionResult"
    )
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let status = try container.decode(Status.self, forKey: .status)

    switch status {
    case .success:
      try Self.rejectAssociatedPayloadKeys(in: container, keys: [.skipReason, .error])
      self = .success
    case .skipped:
      try Self.rejectAssociatedPayloadKeys(in: container, keys: [.error])
      self = try .skipped(container.decode(ActionSkipReason.self, forKey: .skipReason))
    case .failure:
      try Self.rejectAssociatedPayloadKeys(in: container, keys: [.skipReason])
      self = try .failure(container.decode(ActionError.self, forKey: .error))
    }
  }

  /// Encodes an action result as a canonical status payload.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
    case .success:
      try container.encode(Status.success, forKey: .status)
    case .skipped(let reason):
      try container.encode(Status.skipped, forKey: .status)
      try container.encode(reason, forKey: .skipReason)
    case .failure(let error):
      try container.encode(Status.failure, forKey: .status)
      try container.encode(error, forKey: .error)
    }
  }

  private static func rejectAssociatedPayloadKeys(
    in container: KeyedDecodingContainer<CodingKeys>,
    keys: [CodingKeys]
  ) throws {
    for key in keys where container.contains(key) {
      throw DecodingError.dataCorruptedError(
        forKey: key,
        in: container,
        debugDescription: "Action result status does not accept \(key.stringValue)."
      )
    }
  }
}
