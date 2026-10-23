import Foundation

/// A bounded, cancellable reader for shortcut names from the system Shortcuts CLI.
///
/// Listing never runs a shortcut. Hosts own pickers, caching, permission guidance,
/// and whether names may appear in diagnostics.
public struct ShortcutsCatalog: Sendable {
  private let executableURL: URL
  private let timeout: Duration
  private let maximumOutputByteCount: Int

  /// Creates a catalog reader using `/usr/bin/shortcuts list`.
  ///
  /// Invalid timeouts use ten seconds; output limits below one use one byte.
  public init(timeout: Duration = .seconds(10), maximumOutputByteCount: Int = 1_048_576) {
    self.init(
      executableURL: URL(fileURLWithPath: "/usr/bin/shortcuts"),
      timeout: timeout,
      maximumOutputByteCount: maximumOutputByteCount
    )
  }

  init(
    executableURL: URL, timeout: Duration = .seconds(10), maximumOutputByteCount: Int = 1_048_576
  ) {
    self.executableURL = executableURL
    self.timeout = timeout > .zero ? timeout : .seconds(10)
    self.maximumOutputByteCount = max(1, maximumOutputByteCount)
  }

  /// Returns sorted, distinct names, preserving case and names such as `Name` or `-Work`.
  ///
  /// Throws ``ShortcutsCatalogError`` for listing failures, or `CancellationError`
  /// when the calling task is cancelled. The child process is stopped and reaped
  /// before returning after cancellation, timeout, or output overflow. Stderr and
  /// partial output are discarded and never included in errors or logs.
  public func shortcutNames() async throws -> [String] {
    let session = ShortcutsCatalogProcess()
    let data = try await withTaskCancellationHandler {
      try await Task.detached(priority: .userInitiated) {
        try session.run(
          executableURL: executableURL,
          timeout: timeout,
          maximumOutputByteCount: maximumOutputByteCount
        )
      }.value
    } onCancel: {
      session.cancel()
    }
    try Task.checkCancellation()
    guard let output = String(data: data, encoding: .utf8) else {
      throw ShortcutsCatalogError.invalidOutput
    }
    let names = Set(output.components(separatedBy: .newlines).filter { !$0.isEmpty })
    return names.sorted {
      let comparison = $0.localizedCaseInsensitiveCompare($1)
      return comparison == .orderedSame ? $0 < $1 : comparison == .orderedAscending
    }
  }
}

/// A listing failure without shortcut names, paths, or raw process output.
public enum ShortcutsCatalogError: Error, Equatable, Sendable {
  /// The system CLI is missing or not executable.
  case unavailable
  /// The process could not launch, read its output, or exit successfully.
  case executionFailed
  /// Output was not valid UTF-8.
  case invalidOutput
  /// The configured deadline elapsed.
  case timedOut
  /// Stdout exceeded the configured byte limit.
  case outputLimitExceeded
}
