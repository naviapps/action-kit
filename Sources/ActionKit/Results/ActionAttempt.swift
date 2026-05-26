/// A recorded attempt to execute an action.
public struct ActionAttempt: Codable, Sendable, Equatable, Hashable {
  /// Permissions required by this attempt.
  public let requiredPermissions: Set<ActionPermission>
  /// Whether this attempt used a fallback execution path.
  public let isFallback: Bool
  /// The result produced by the attempt.
  public let result: ActionResult
  /// How long the step took, when measured by the executor.
  public let duration: Duration?

  /// Creates an action attempt.
  ///
  /// - Parameters:
  ///   - requiredPermissions: Permissions required by the attempted path.
  ///   - isFallback: Whether the attempt used a fallback execution path.
  ///   - result: The result produced by the attempt.
  ///   - duration: How long the attempt took, when measured by the executor.
  public init(
    requiredPermissions: Set<ActionPermission>,
    isFallback: Bool,
    result: ActionResult,
    duration: Duration? = nil
  ) {
    self.requiredPermissions = requiredPermissions
    self.isFallback = isFallback
    self.result = result
    self.duration = duration
  }

  package init(step: ActionStep, result: ActionResult, duration: Duration? = nil) {
    self.init(
      requiredPermissions: step.requiredPermissions,
      isFallback: step.isFallback,
      result: result,
      duration: duration
    )
  }
}

extension ActionAttempt {
  private enum CodingKeys: String, CodingKey {
    case requiredPermissions
    case isFallback
    case result
    case durationSeconds
  }

  /// Decodes an action attempt from its public result payload.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    requiredPermissions = Set(
      try container.decode([ActionPermission].self, forKey: .requiredPermissions))
    isFallback = try container.decode(Bool.self, forKey: .isFallback)
    result = try container.decode(ActionResult.self, forKey: .result)
    if let durationSeconds = try container.decodeIfPresent(Double.self, forKey: .durationSeconds) {
      duration = try Duration(
        secondsValue: durationSeconds,
        codingPath: container.codingPath + [CodingKeys.durationSeconds]
      )
    } else {
      duration = nil
    }
  }

  /// Encodes an action attempt with stable permission array ordering.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(requiredPermissions.stableCodableOrder, forKey: .requiredPermissions)
    try container.encode(isFallback, forKey: .isFallback)
    try container.encode(result, forKey: .result)
    if let duration {
      let durationCodingPath = container.codingPath + [CodingKeys.durationSeconds]
      try container.encode(
        duration.encodedSecondsValue(codingPath: durationCodingPath),
        forKey: .durationSeconds
      )
    }
  }
}

extension Duration {
  private static let attosecondsPerSecond: Int64 = 1_000_000_000_000_000_000

  fileprivate init(secondsValue: Double, codingPath: [CodingKey]) throws {
    func throwInvalidDuration() throws -> Never {
      throw DecodingError.dataCorrupted(
        .init(
          codingPath: codingPath,
          debugDescription: "durationSeconds must be a finite non-negative number in range"
        )
      )
    }

    guard secondsValue.isFinite, secondsValue >= 0 else {
      try throwInvalidDuration()
    }
    let wholeSeconds = secondsValue.rounded(.towardZero)
    guard var secondsComponent = Int64(exactly: wholeSeconds) else {
      try throwInvalidDuration()
    }
    let fractionalSeconds = secondsValue - wholeSeconds
    var attosecondsComponent = Int64(
      (fractionalSeconds * Double(Self.attosecondsPerSecond)).rounded()
    )
    if attosecondsComponent == Self.attosecondsPerSecond {
      guard secondsComponent < Int64.max else {
        try throwInvalidDuration()
      }
      secondsComponent += 1
      attosecondsComponent = 0
    }

    self.init(secondsComponent: secondsComponent, attosecondsComponent: attosecondsComponent)
  }

  fileprivate var secondsValue: Double {
    let components = components
    return Double(components.seconds)
      + Double(components.attoseconds) / Double(Self.attosecondsPerSecond)
  }

  fileprivate func encodedSecondsValue(codingPath: [CodingKey]) throws -> Double {
    func throwInvalidDuration() throws -> Never {
      throw EncodingError.invalidValue(
        self,
        .init(
          codingPath: codingPath,
          debugDescription: "duration must be a finite non-negative value in range"
        )
      )
    }

    guard self >= .zero else {
      try throwInvalidDuration()
    }
    let secondsValue = secondsValue
    guard secondsValue.isFinite else {
      try throwInvalidDuration()
    }
    do {
      _ = try Duration(secondsValue: secondsValue, codingPath: codingPath)
    } catch {
      try throwInvalidDuration()
    }
    return secondsValue
  }
}
