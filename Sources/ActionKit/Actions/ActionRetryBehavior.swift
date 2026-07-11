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
