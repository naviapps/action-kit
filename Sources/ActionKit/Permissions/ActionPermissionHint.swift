/// A permission requirement and the action-specific reason it is needed.
public struct ActionPermissionHint: Sendable, Equatable, Hashable, Codable {
  /// The required permission.
  public let permission: ActionPermission
  /// The reason code a host app can map to user-facing copy.
  public let reason: ActionPermissionReason

  /// Creates a permission hint.
  ///
  /// - Parameters:
  ///   - permission: The required macOS privacy permission.
  ///   - reason: The action-specific reason the permission is needed.
  public init(permission: ActionPermission, reason: ActionPermissionReason) {
    self.permission = permission
    self.reason = reason
  }
}

extension ActionPermissionHint {
  private enum CodingKeys: String, CodingKey {
    case permission
    case reason
  }

  /// Decodes a permission hint from its canonical permission and reason fields.
  public init(from decoder: Decoder) throws {
    try decoder.rejectUnknownKeys(
      allowed: [CodingKeys.permission, .reason],
      debugName: "ActionPermissionHint"
    )
    let container = try decoder.container(keyedBy: CodingKeys.self)
    permission = try container.decode(ActionPermission.self, forKey: .permission)
    reason = try container.decode(ActionPermissionReason.self, forKey: .reason)
  }

  /// Encodes a permission hint with its canonical permission and reason fields.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(permission, forKey: .permission)
    try container.encode(reason, forKey: .reason)
  }
}
