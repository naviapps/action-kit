import Darwin
import Foundation

/// Owns only the process created for a single listing request.
final class ShortcutsCatalogProcess: @unchecked Sendable {
  private enum StopReason {
    case cancelled
    case failed(ShortcutsCatalogError)
  }

  private let lock = NSLock()
  private var process: Process?
  private var stopReason: StopReason?

  func run(executableURL: URL, timeout: Duration, maximumOutputByteCount: Int) throws -> Data {
    let pipe = Pipe()
    let child = Process()
    child.executableURL = executableURL
    child.arguments = ["list"]
    child.standardInput = FileHandle.nullDevice
    child.standardOutput = pipe
    child.standardError = FileHandle.nullDevice

    try lock.withLock {
      try checkStopReason()
      guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
        throw ShortcutsCatalogError.unavailable
      }
      process = child
      do {
        try child.run()
      } catch {
        process = nil
        throw ShortcutsCatalogError.executionFailed
      }
    }
    // The parent must not keep the pipe's write end open while waiting for EOF.
    try? pipe.fileHandleForWriting.close()
    let deadline = ContinuousClock.now.advanced(by: timeout)
    let descriptor = pipe.fileHandleForReading.fileDescriptor
    let flags = fcntl(descriptor, F_GETFL)
    guard flags >= 0, fcntl(descriptor, F_SETFL, flags | O_NONBLOCK) >= 0 else {
      stop(.failed(.executionFailed))
      child.waitUntilExit()
      throw ShortcutsCatalogError.executionFailed
    }
    defer {
      try? pipe.fileHandleForReading.close()
      lock.withLock { process = nil }
    }

    var output = Data()
    var buffer = [UInt8](repeating: 0, count: 8_192)
    while !stopIfNeeded(deadline: deadline) {
      let count = buffer.withUnsafeMutableBytes {
        Darwin.read(descriptor, $0.baseAddress, $0.count)
      }
      if count > 0 {
        guard count <= maximumOutputByteCount - output.count else {
          stop(.failed(.outputLimitExceeded))
          break
        }
        output.append(contentsOf: buffer.prefix(count))
      } else if count == 0 {
        break
      } else if errno == EINTR {
        continue
      } else if errno == EAGAIN || errno == EWOULDBLOCK {
        // Nonblocking reads and a bounded poll keep cancellation/deadlines valid
        // even when the process produces no output or a descendant holds stdout.
        var item = pollfd(fd: descriptor, events: Int16(POLLIN), revents: 0)
        if poll(&item, 1, 50) < 0, errno != EINTR {
          stop(.failed(.executionFailed))
        }
      } else {
        stop(.failed(.executionFailed))
      }
    }
    // EOF need not mean process exit. Continue respecting the same deadline.
    while child.isRunning, !stopIfNeeded(deadline: deadline) {
      _ = poll(nil, 0, 50)
    }
    child.waitUntilExit()
    try lock.withLock { try checkStopReason() }
    guard child.terminationStatus == 0 else { throw ShortcutsCatalogError.executionFailed }
    return output
  }

  private func stopIfNeeded(deadline: ContinuousClock.Instant) -> Bool {
    if ContinuousClock.now >= deadline { stop(.failed(.timedOut)) }
    return lock.withLock {
      if case nil = stopReason { return false }
      return true
    }
  }

  func cancel() {
    stop(.cancelled)
  }

  private func checkStopReason() throws {
    switch stopReason {
    case .cancelled: throw CancellationError()
    case let .failed(error): throw error
    case nil: break
    }
  }

  private func stop(_ reason: StopReason) {
    let needsEscalation = lock.withLock {
      guard case nil = stopReason else { return false }
      stopReason = reason
      guard let process, process.isRunning else { return false }
      process.terminate()
      return true
    }
    guard needsEscalation else { return }
    Task.detached { [self] in
      try? await Task.sleep(for: .milliseconds(100))
      lock.withLock {
        guard let process, process.isRunning else { return }
        // The same Process is still running; never signal a remembered PID after
        // it has terminated. This also bounds children that ignore SIGTERM.
        _ = Darwin.kill(process.processIdentifier, SIGKILL)
      }
    }
  }
}
