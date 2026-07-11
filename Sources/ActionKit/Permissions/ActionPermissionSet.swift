/// Permission requirements split between primary and fallback execution paths.
public struct ActionPermissionSet: Codable, Sendable, Equatable, Hashable {
  /// Permissions required by primary execution paths.
  public let primary: Set<ActionPermission>
  /// Permissions required by fallback execution paths.
  public let fallback: Set<ActionPermission>

  /// Creates permission requirements for primary and fallback execution paths.
  ///
  /// - Parameters:
  ///   - primary: Permissions required by primary execution paths.
  ///   - fallback: Permissions required by fallback execution paths.
  public init(primary: Set<ActionPermission>, fallback: Set<ActionPermission>) {
    self.primary = primary
    self.fallback = fallback
  }

  /// Permissions required only by fallback execution paths.
  public var fallbackOnly: Set<ActionPermission> {
    fallback.subtracting(primary)
  }

  /// Every permission that may be needed by any execution path.
  public var all: Set<ActionPermission> {
    primary.union(fallback)
  }

  /// Whether no execution path requires a permission.
  public var isEmpty: Bool {
    primary.isEmpty && fallback.isEmpty
  }
}

extension ActionPermissionSet {
  private enum CodingKeys: String, CodingKey {
    case primary
    case fallback
  }

  /// Decodes permission requirements from primary and fallback permission arrays.
  public init(from decoder: Decoder) throws {
    try decoder.rejectUnknownKeys(
      allowed: [CodingKeys.primary, .fallback],
      debugName: "ActionPermissionSet"
    )
    let container = try decoder.container(keyedBy: CodingKeys.self)
    primary = try container.decodeCanonicalPermissionSet(forKey: .primary)
    fallback = try container.decodeCanonicalPermissionSet(forKey: .fallback)
  }

  /// Encodes permission requirements with canonical permission array ordering.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(primary.canonicalCodableOrder, forKey: .primary)
    try container.encode(fallback.canonicalCodableOrder, forKey: .fallback)
  }
}

extension Set where Element == ActionPermission {
  package var canonicalCodableOrder: [ActionPermission] {
    sorted { $0.rawValue < $1.rawValue }
  }
}

extension KeyedDecodingContainer {
  func decodeCanonicalPermissionSet(forKey key: Key) throws -> Set<ActionPermission> {
    let permissions = try decode([ActionPermission].self, forKey: key)
    let permissionSet = Set(permissions)
    guard permissionSet.count == permissions.count else {
      throw DecodingError.dataCorruptedError(
        forKey: key,
        in: self,
        debugDescription: "\(key.stringValue) must not contain duplicate permissions."
      )
    }
    return permissionSet
  }
}
