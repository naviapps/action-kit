/// Conservative retry-policy guidance for host-controlled execution.
///
/// Retry behavior describes how a host should think about repeating an action after a transient
/// failure. It is not a runtime guarantee: the current app, focused element, window state, and
/// system prompts can still change the result of any live macOS automation.
public enum ActionRetryBehavior: String, Codable, Hashable, CaseIterable, Sendable {
  /// Retrying is expected to converge on the same user-visible state in normal conditions.
  case safe
  /// Retrying depends on the current app, focus, selection, window, or system state.
  case contextDependent = "context-dependent"
  /// Retrying may repeat a non-idempotent or disruptive user-visible side effect.
  case unsafe
}

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
