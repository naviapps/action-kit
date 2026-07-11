/// The final outcome of executing an action.
public struct ActionOutcome: Codable, Sendable, Equatable, Hashable {
  /// The ordered execution attempts recorded while producing the final result.
  public let attempts: [ActionAttempt]

  package init(attempts: [ActionAttempt]) {
    if attempts.isEmpty {
      self.attempts = [
        .init(
          requiredPermissions: [],
          isFallback: false,
          result: .failure(.internalError("No execution attempts were recorded"))
        )
      ]
    } else {
      self.attempts = attempts
    }
  }

  /// The last attempt result.
  public var finalResult: ActionResult {
    attempts[attempts.index(before: attempts.endIndex)].result
  }

  /// The last successful attempt, if any.
  public var successfulAttempt: ActionAttempt? {
    attempts.last { $0.result == .success }
  }

  /// Whether any fallback execution path was attempted.
  public var didAttemptFallback: Bool {
    attempts.contains { $0.isFallback }
  }
}

extension ActionOutcome {
  private enum CodingKeys: String, CodingKey {
    case finalResult
    case attempts
  }

  /// Decodes an action outcome and rejects payloads whose final result conflicts with attempts.
  public init(from decoder: Decoder) throws {
    try decoder.rejectUnknownKeys(
      allowed: [CodingKeys.finalResult, .attempts],
      debugName: "ActionOutcome"
    )
    let container = try decoder.container(keyedBy: CodingKeys.self)
    attempts = try container.decode([ActionAttempt].self, forKey: .attempts)
    guard !attempts.isEmpty else {
      throw DecodingError.dataCorruptedError(
        forKey: .attempts,
        in: container,
        debugDescription: "attempts must contain at least one recorded action attempt."
      )
    }
    let decodedFinalResult = try container.decode(ActionResult.self, forKey: .finalResult)
    guard decodedFinalResult == finalResult else {
      throw DecodingError.dataCorruptedError(
        forKey: .finalResult,
        in: container,
        debugDescription: "finalResult must match the last action attempt result."
      )
    }
  }

  /// Encodes an action outcome with a derived final result.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(finalResult, forKey: .finalResult)
    try container.encode(attempts, forKey: .attempts)
  }
}
