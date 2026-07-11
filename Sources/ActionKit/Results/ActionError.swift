import Foundation

/// A structured action execution error.
public struct ActionError: Codable, Error, Sendable, Equatable, Hashable {
  /// The canonical error category.
  public let code: ActionErrorCode
  /// A diagnostic message intended for logs or developer-facing UI.
  public let diagnosticMessage: String
  /// The permission associated with a permission failure.
  public let permission: ActionPermission?
  /// The AppleScript error number associated with an Automation denial or AppleScript failure.
  public let appleScriptErrorNumber: Int?

  private init(
    code: ActionErrorCode,
    diagnosticMessage: String,
    permission: ActionPermission? = nil,
    appleScriptErrorNumber: Int? = nil
  ) {
    self.code = code
    self.diagnosticMessage = diagnosticMessage.trimmingCharacters(in: .whitespacesAndNewlines)
    self.permission = permission
    self.appleScriptErrorNumber = appleScriptErrorNumber
  }
}

extension ActionError: LocalizedError {
  /// The diagnostic message exposed through Swift's standard error description bridge.
  public var errorDescription: String? {
    diagnosticMessage
  }
}

extension ActionError {
  private enum CodingKeys: String, CodingKey {
    case code
    case diagnosticMessage
    case permission
    case appleScriptErrorNumber
  }

  /// Decodes an action error and rejects payload fields that do not match the error code.
  public init(from decoder: Decoder) throws {
    try decoder.rejectUnknownKeys(
      allowed: [
        CodingKeys.code,
        .diagnosticMessage,
        .permission,
        .appleScriptErrorNumber,
      ],
      debugName: "ActionError"
    )
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let code = try container.decode(ActionErrorCode.self, forKey: .code)
    let diagnosticMessage = try container.decode(String.self, forKey: .diagnosticMessage)
    guard !diagnosticMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw DecodingError.dataCorruptedError(
        forKey: .diagnosticMessage,
        in: container,
        debugDescription: "diagnosticMessage must not be empty."
      )
    }
    let permission = try container.decodeIfPresentRejectingNull(
      ActionPermission.self,
      forKey: .permission
    )
    let appleScriptErrorNumber = try container.decodeIfPresentRejectingNull(
      Int.self,
      forKey: .appleScriptErrorNumber
    )

    switch code {
    case .permissionDenied:
      guard permission != nil else {
        throw DecodingError.dataCorruptedError(
          forKey: .permission,
          in: container,
          debugDescription: "permission-denied errors must include permission."
        )
      }
      if permission != .automation {
        try Self.rejectField(.appleScriptErrorNumber, in: container)
      }
    case .appleScriptFailed:
      try Self.rejectField(.permission, in: container)
    case .invalidInput, .notFound, .openFailed, .screenCaptureFailed, .internalError:
      try Self.rejectField(.permission, in: container)
      try Self.rejectField(.appleScriptErrorNumber, in: container)
    }

    self.init(
      code: code,
      diagnosticMessage: diagnosticMessage,
      permission: permission,
      appleScriptErrorNumber: appleScriptErrorNumber
    )
  }

  /// Encodes an action error as a canonical structured payload.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(code, forKey: .code)
    try container.encode(diagnosticMessage, forKey: .diagnosticMessage)
    try container.encodeIfPresent(permission, forKey: .permission)
    try container.encodeIfPresent(appleScriptErrorNumber, forKey: .appleScriptErrorNumber)
  }

  private static func rejectField(
    _ key: CodingKeys,
    in container: KeyedDecodingContainer<CodingKeys>
  ) throws {
    guard container.contains(key) else { return }
    throw DecodingError.dataCorruptedError(
      forKey: key,
      in: container,
      debugDescription: "\(key.stringValue) is not valid for this error code."
    )
  }
}

extension ActionError {
  /// Creates an invalid-input error.
  ///
  /// - Parameter diagnosticMessage: Developer-facing diagnostic text.
  /// - Returns: A structured invalid-input error.
  public static func invalidInput(_ diagnosticMessage: String) -> Self {
    .init(
      code: .invalidInput,
      diagnosticMessage: normalizedDiagnosticMessage(
        diagnosticMessage,
        fallback: "Invalid input"
      )
    )
  }

  /// Creates a permission-denied error.
  ///
  /// - Parameter permission: The permission that was denied or unavailable.
  /// - Returns: A structured permission-denied error.
  public static func permissionDenied(_ permission: ActionPermission) -> Self {
    .init(
      code: .permissionDenied,
      diagnosticMessage: permissionDeniedDiagnosticMessage(permission),
      permission: permission
    )
  }

  /// Creates an Automation permission-denied error, optionally including its AppleScript error number.
  ///
  /// - Parameter appleScriptErrorNumber: The AppleScript error number reported by macOS.
  /// - Returns: A structured Automation permission-denied error.
  public static func automationPermissionDenied(appleScriptErrorNumber: Int? = nil) -> Self {
    .init(
      code: .permissionDenied,
      diagnosticMessage: automationPermissionDeniedDiagnosticMessage(
        appleScriptErrorNumber: appleScriptErrorNumber
      ),
      permission: .automation,
      appleScriptErrorNumber: appleScriptErrorNumber
    )
  }

  /// Creates a not-found error.
  ///
  /// - Parameter diagnosticMessage: Developer-facing diagnostic text.
  /// - Returns: A structured not-found error.
  public static func notFound(_ diagnosticMessage: String) -> Self {
    .init(
      code: .notFound,
      diagnosticMessage: normalizedDiagnosticMessage(
        diagnosticMessage,
        fallback: "Not found"
      )
    )
  }

  /// Creates an open-failed error.
  ///
  /// - Parameter diagnosticMessage: Developer-facing diagnostic text.
  /// - Returns: A structured open-failed error.
  public static func openFailed(_ diagnosticMessage: String) -> Self {
    .init(
      code: .openFailed,
      diagnosticMessage: normalizedDiagnosticMessage(
        diagnosticMessage,
        fallback: "Open failed"
      )
    )
  }

  /// Creates an AppleScript failure error, optionally including its AppleScript error number.
  ///
  /// - Parameters:
  ///   - diagnosticMessage: Developer-facing diagnostic text.
  ///   - appleScriptErrorNumber: The AppleScript error number reported by macOS.
  /// - Returns: A structured AppleScript failure error.
  public static func appleScriptFailed(
    _ diagnosticMessage: String,
    appleScriptErrorNumber: Int? = nil
  ) -> Self {
    .init(
      code: .appleScriptFailed,
      diagnosticMessage: appleScriptFailedDiagnosticMessage(
        diagnosticMessage,
        appleScriptErrorNumber: appleScriptErrorNumber
      ),
      appleScriptErrorNumber: appleScriptErrorNumber
    )
  }

  /// Creates a screen-capture failure error.
  ///
  /// - Parameter diagnosticMessage: Developer-facing diagnostic text.
  /// - Returns: A structured screen-capture failure error.
  public static func screenCaptureFailed(_ diagnosticMessage: String) -> Self {
    .init(
      code: .screenCaptureFailed,
      diagnosticMessage: normalizedDiagnosticMessage(
        diagnosticMessage,
        fallback: "Screen capture failed"
      )
    )
  }

  /// Creates an internal execution error.
  ///
  /// - Parameter diagnosticMessage: Developer-facing diagnostic text.
  /// - Returns: A structured internal execution error.
  public static func internalError(_ diagnosticMessage: String) -> Self {
    .init(
      code: .internalError,
      diagnosticMessage: normalizedDiagnosticMessage(
        diagnosticMessage,
        fallback: "Internal error"
      )
    )
  }

  private static func normalizedDiagnosticMessage(
    _ diagnosticMessage: String,
    fallback: String
  ) -> String {
    let normalized = diagnosticMessage.trimmingCharacters(in: .whitespacesAndNewlines)
    return normalized.isEmpty ? fallback : normalized
  }

  private static func permissionDeniedDiagnosticMessage(_ permission: ActionPermission) -> String {
    "Permission denied: \(permission.rawValue)"
  }

  private static func automationPermissionDeniedDiagnosticMessage(
    appleScriptErrorNumber: Int?
  ) -> String {
    let message = permissionDeniedDiagnosticMessage(.automation)
    guard let appleScriptErrorNumber else { return message }
    return "\(message) (AppleScript error number \(appleScriptErrorNumber))"
  }

  private static func appleScriptFailedDiagnosticMessage(
    _ diagnosticMessage: String,
    appleScriptErrorNumber: Int?
  ) -> String {
    let message = normalizedDiagnosticMessage(
      diagnosticMessage,
      fallback: "AppleScript failed"
    )
    guard let appleScriptErrorNumber else { return message }
    guard !message.contains("AppleScript error number") else { return message }
    return "\(message) (AppleScript error number \(appleScriptErrorNumber))"
  }
}
