/// The final outcome of executing an action.
public struct ActionOutcome: Codable, Sendable, Equatable, Hashable {
  /// The ordered execution attempts recorded while producing the final result.
  public let attempts: [ActionAttempt]

  /// Creates an action outcome from ordered execution attempts.
  ///
  /// - Parameter attempts: The ordered attempts recorded during execution.
  public init(attempts: [ActionAttempt]) {
    self.attempts = attempts
  }

  /// The last attempt result, or an internal error when no attempts were recorded.
  public var finalResult: ActionResult {
    attempts.last?.result ?? .failure(.internalError("No execution attempts were recorded"))
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
    let container = try decoder.container(keyedBy: CodingKeys.self)
    attempts = try container.decode([ActionAttempt].self, forKey: .attempts)
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
