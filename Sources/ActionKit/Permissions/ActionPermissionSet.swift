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
    let container = try decoder.container(keyedBy: CodingKeys.self)
    primary = Set(try container.decode([ActionPermission].self, forKey: .primary))
    fallback = Set(try container.decode([ActionPermission].self, forKey: .fallback))
  }

  /// Encodes permission requirements with stable permission array ordering.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(primary.stableCodableOrder, forKey: .primary)
    try container.encode(fallback.stableCodableOrder, forKey: .fallback)
  }
}

extension Set where Element == ActionPermission {
  package var stableCodableOrder: [ActionPermission] {
    sorted { $0.rawValue < $1.rawValue }
  }
}
