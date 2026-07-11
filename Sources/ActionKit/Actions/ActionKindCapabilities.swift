/// Static execution-semantics metadata for an action kind.
///
/// These values are conservative host-policy hints for action pickers, confirmation UI, retry
/// decisions, and tool surfaces. They describe the action kind in advance, but they do not replace
/// runtime preflight, permission checks, target availability checks, or app-specific policy.
public struct ActionKindCapabilities: Codable, Equatable, Hashable, Sendable {
  /// Whether the action depends on the current frontmost application, first responder, or selection.
  public let requiresFrontmostApplication: Bool
  /// Whether the action depends on a currently focused window.
  public let requiresFocusedWindow: Bool
  /// Whether live execution asks the user to interactively choose a region, window, or target.
  public let requiresInteractiveSelection: Bool
  /// Whether the action can discard, remove, quit, or materially alter user work or system state.
  public let isDestructive: Bool
  /// Conservative retry-policy guidance for host apps and automation tooling.
  public let retryBehavior: ActionRetryBehavior

  /// Creates static execution-semantics metadata for an action kind.
  ///
  /// - Parameters:
  ///   - requiresFrontmostApplication: Whether execution depends on the frontmost app, first
  ///     responder, or selection.
  ///   - requiresFocusedWindow: Whether execution depends on a currently focused window.
  ///   - requiresInteractiveSelection: Whether execution asks the user to interactively choose a
  ///     region, window, or target during the action.
  ///   - isDestructive: Whether execution can discard, remove, quit, or materially alter user
  ///     work or system state.
  ///   - retryBehavior: Conservative guidance for host retry policy.
  public init(
    requiresFrontmostApplication: Bool = false,
    requiresFocusedWindow: Bool = false,
    requiresInteractiveSelection: Bool = false,
    isDestructive: Bool = false,
    retryBehavior: ActionRetryBehavior = .contextDependent
  ) {
    self.requiresFrontmostApplication = requiresFrontmostApplication
    self.requiresFocusedWindow = requiresFocusedWindow
    self.requiresInteractiveSelection = requiresInteractiveSelection
    self.isDestructive = isDestructive
    self.retryBehavior = retryBehavior
  }
}

extension ActionKindCapabilities {
  private enum CodingKeys: String, CodingKey {
    case requiresFrontmostApplication
    case requiresFocusedWindow
    case requiresInteractiveSelection
    case isDestructive
    case retryBehavior
  }

  /// Decodes execution-semantics metadata from its canonical catalog fields.
  public init(from decoder: Decoder) throws {
    try decoder.rejectUnknownKeys(
      allowed: [
        CodingKeys.requiresFrontmostApplication,
        .requiresFocusedWindow,
        .requiresInteractiveSelection,
        .isDestructive,
        .retryBehavior,
      ],
      debugName: "ActionKindCapabilities"
    )
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      requiresFrontmostApplication: try container.decode(
        Bool.self,
        forKey: .requiresFrontmostApplication
      ),
      requiresFocusedWindow: try container.decode(Bool.self, forKey: .requiresFocusedWindow),
      requiresInteractiveSelection: try container.decode(
        Bool.self,
        forKey: .requiresInteractiveSelection
      ),
      isDestructive: try container.decode(Bool.self, forKey: .isDestructive),
      retryBehavior: try container.decode(ActionRetryBehavior.self, forKey: .retryBehavior)
    )
  }

  /// Encodes execution-semantics metadata as its canonical catalog fields.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(
      requiresFrontmostApplication,
      forKey: .requiresFrontmostApplication
    )
    try container.encode(requiresFocusedWindow, forKey: .requiresFocusedWindow)
    try container.encode(requiresInteractiveSelection, forKey: .requiresInteractiveSelection)
    try container.encode(isDestructive, forKey: .isDestructive)
    try container.encode(retryBehavior, forKey: .retryBehavior)
  }
}
