import Foundation

/// Errors produced while encoding or decoding JSON action envelopes.
public enum ActionCodecError: LocalizedError, Sendable, Equatable, Hashable {
  /// The encoded envelope uses a schema version this package cannot decode.
  case unsupportedVersion(Int)

  /// A localized description of the codec error.
  public var errorDescription: String? {
    switch self {
    case .unsupportedVersion(let version):
      "Unsupported action envelope version: \(version)."
    }
  }
}
