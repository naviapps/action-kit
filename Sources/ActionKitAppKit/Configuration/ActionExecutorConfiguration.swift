import ApplicationServices

/// Host-provided configuration for execution behavior, diagnostics, and recovery.
///
/// This is the primary integration surface for apps embedding ActionKit.
public struct ActionExecutorConfiguration: Sendable {
  /// Log severity emitted by the action executor.
  public enum LogLevel: String, Codable, CaseIterable, Hashable, Sendable {
    /// Detailed diagnostic information.
    case debug
    /// Informational execution progress.
    case info
    /// Recoverable behavior that may need attention.
    case warning
    /// A failed execution path or unexpected error.
    case error
  }

  /// Host-provided hooks for permission readiness and recovery UX.
  ///
  /// ActionKit executes actions; the host app decides how permission prompts and
  /// recovery guidance are presented.
  public struct Permissions: Sendable {
    /// Returns whether Accessibility-backed execution may run.
    public let ensureAccessibility: @MainActor @Sendable () async -> Bool
    /// Returns whether AppleScript-backed execution may run.
    ///
    /// The default allows execution so macOS can report Automation denial through
    /// the AppleScript result. Override this when the host has its own readiness
    /// or onboarding policy.
    public let ensureAutomation: @MainActor @Sendable () async -> Bool
    /// Called when Automation is denied after execution attempts complete.
    public let onAutomationDenied:
      @MainActor @Sendable (_ appleScriptErrorNumber: Int?) async ->
        Void
    /// Called after live Screen Recording access checks fail.
    public let onScreenRecordingRequired: @MainActor @Sendable () async -> Void

    /// Creates permission hooks.
    ///
    /// - Parameters:
    ///   - ensureAccessibility: Hook that returns Accessibility readiness.
    ///   - ensureAutomation: Hook that returns Automation readiness.
    ///   - onAutomationDenied: Recovery hook called after Automation denial.
    ///   - onScreenRecordingRequired: Recovery hook called after Screen Recording denial.
    public init(
      ensureAccessibility: @escaping @MainActor @Sendable () async -> Bool = {
        AXIsProcessTrusted()
      },
      ensureAutomation: @escaping @MainActor @Sendable () async -> Bool = { true },
      onAutomationDenied:
        @escaping @MainActor @Sendable (
          _ appleScriptErrorNumber: Int?
        ) async -> Void = { _ in },
      onScreenRecordingRequired: @escaping @MainActor @Sendable () async -> Void = {}
    ) {
      self.ensureAccessibility = ensureAccessibility
      self.ensureAutomation = ensureAutomation
      self.onAutomationDenied = onAutomationDenied
      self.onScreenRecordingRequired = onScreenRecordingRequired
    }
  }

  /// Permission and recovery hooks used by live execution.
  public let permissions: Permissions
  /// Receives executor diagnostics.
  public let log: @Sendable (_ level: LogLevel, _ message: String) -> Void

  /// Creates executor configuration.
  ///
  /// - Parameters:
  ///   - permissions: Permission and recovery hooks used by live execution.
  ///   - log: Diagnostic sink used by the executor.
  public init(
    permissions: Permissions = .init(),
    log: @escaping @Sendable (_ level: LogLevel, _ message: String) -> Void = { _, _ in }
  ) {
    self.permissions = permissions
    self.log = log
  }
}
