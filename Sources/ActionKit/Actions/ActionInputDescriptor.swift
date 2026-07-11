/// Metadata describing the host-supplied input required by an action kind.
///
/// Use this when building action pickers, dynamic forms, or tool surfaces before an executable
/// ``Action`` exists.
public struct ActionInputDescriptor: Equatable, Hashable, Sendable {
  /// Input-free descriptor used by action kinds that do not require host-supplied values.
  public static let none = ActionInputDescriptor(canonicalShape: .none, parameter: nil)

  /// The structural shape of the required input.
  public let shape: ActionInputShape
  /// Parameter metadata for the required input.
  ///
  /// This is present when ``requiresInput`` is `true` and absent for ``none``.
  public let parameter: ActionInputParameter?

  /// Whether this descriptor requires a host-supplied ``ActionInput``.
  ///
  /// This is derived from ``shape`` and is not encoded as separate metadata.
  public var requiresInput: Bool {
    shape != .none
  }

  /// A representative input value for this descriptor, when input is required.
  public var exampleInput: ActionInput? {
    parameter?.exampleInput
  }

  /// Creates an input descriptor for an action kind.
  ///
  /// - Parameters:
  ///   - shape: The structural input shape required by the action kind.
  ///   - parameter: Parameter metadata. Required when `shape` is not ``ActionInputShape/none``.
  ///
  /// Returns `nil` when required-input metadata is missing, `parameter.exampleInput` does not
  /// match `shape`, or input-free metadata declares a parameter.
  public init?(shape: ActionInputShape, parameter: ActionInputParameter? = nil) {
    if shape == .none {
      guard parameter == nil else {
        return nil
      }

      self.init(canonicalShape: shape, parameter: nil)
      return
    }

    guard let parameter, Self.isValidExampleInput(parameter.exampleInput, for: shape) else {
      return nil
    }

    self.init(canonicalShape: shape, parameter: parameter)
  }

  init(
    canonicalShape shape: ActionInputShape,
    parameter: ActionInputParameter?
  ) {
    self.shape = shape
    self.parameter = parameter
  }
}

extension ActionInputDescriptor: Codable {
  private enum CodingKeys: String, CodingKey {
    case shape
    case parameter
  }

  /// Decodes an input descriptor and rejects values that do not match descriptor invariants.
  public init(from decoder: Decoder) throws {
    try decoder.rejectUnknownKeys(
      allowed: [CodingKeys.shape, .parameter],
      debugName: "ActionInputDescriptor"
    )
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let shape = try container.decode(ActionInputShape.self, forKey: .shape)
    let parameter = try container.decodeIfPresentRejectingNull(
      ActionInputParameter.self,
      forKey: .parameter
    )

    guard
      let descriptor = Self(shape: shape, parameter: parameter)
    else {
      throw DecodingError.dataCorruptedError(
        forKey: .parameter,
        in: container,
        debugDescription: "Descriptor metadata must be complete and shape-matched."
      )
    }

    self = descriptor
  }

  /// Encodes normalized descriptor metadata.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(shape, forKey: .shape)
    try container.encodeIfPresent(parameter, forKey: .parameter)
  }

  private static func isValidExampleInput(
    _ input: ActionInput,
    for shape: ActionInputShape
  ) -> Bool {
    guard input.shape == shape else {
      return false
    }

    return input.normalized == input
  }
}
