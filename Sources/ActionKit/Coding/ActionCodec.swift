import Foundation

private struct ActionEnvelope: Sendable {
  let action: Action
}

extension ActionEnvelope: Codable {
  private enum CodingKeys: String, CodingKey {
    case version
    case action
  }

  init(from decoder: Decoder) throws {
    try decoder.rejectUnknownKeys(
      allowed: [CodingKeys.version, .action],
      debugName: "ActionEnvelope"
    )
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let version = try container.decode(Int.self, forKey: .version)
    guard version == ActionCodec.currentVersion else {
      throw ActionCodecError.unsupportedVersion(version)
    }
    self.action = try container.decode(Action.self, forKey: .action)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(ActionCodec.currentVersion, forKey: .version)
    try container.encode(action, forKey: .action)
  }
}

/// Encodes and decodes versioned JSON action envelopes.
public enum ActionCodec {
  /// The JSON envelope version emitted by this codec.
  public static let currentVersion = 1

  /// Encodes an action into a versioned JSON envelope.
  ///
  /// - Parameters:
  ///   - action: The action to encode.
  ///   - encoder: The JSON encoder used for the envelope.
  /// - Returns: The encoded JSON envelope.
  /// - Throws: Any encoding error produced by the encoder.
  public static func encode(
    _ action: Action,
    encoder: JSONEncoder = JSONEncoder()
  ) throws -> Data {
    try encoder.encode(ActionEnvelope(action: action))
  }

  /// Decodes an action from a versioned JSON envelope.
  ///
  /// - Parameters:
  ///   - data: The encoded JSON envelope.
  ///   - decoder: The JSON decoder used for the envelope.
  /// - Returns: The decoded action.
  /// - Throws: `ActionCodecError.unsupportedVersion` or any decoding error produced by the decoder.
  public static func decode(
    _ data: Data,
    decoder: JSONDecoder = JSONDecoder()
  ) throws -> Action {
    let envelope = try decoder.decode(ActionEnvelope.self, from: data)
    return envelope.action
  }
}
