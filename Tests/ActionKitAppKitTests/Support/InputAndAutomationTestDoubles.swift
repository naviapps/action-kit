import ApplicationServices
import Foundation

@testable import ActionKitAppKit

final class TestKeyEventPoster: KeyEventPosting, @unchecked Sendable {
  private let lock = NSLock()
  private var events: [(virtualKey: CGKeyCode, flags: CGEventFlags)] = []
  private let result: Bool

  init(result: Bool = true) {
    self.result = result
  }

  func postKeyStroke(virtualKey: CGKeyCode, flags: CGEventFlags) -> Bool {
    lock.withLock {
      events.append((virtualKey, flags))
    }
    return result
  }

  var postedEvents: [(virtualKey: CGKeyCode, flags: CGEventFlags)] {
    lock.withLock {
      events
    }
  }
}

struct TestAppleScriptExecutor: AppleScriptExecuting {
  let result: Result<Void, AppleScriptExecutionFailure>

  init(result: Result<Void, AppleScriptExecutionFailure> = .success(())) {
    self.result = result
  }

  func execute(source _: String) async -> Result<Void, AppleScriptExecutionFailure> {
    result
  }
}

actor TestSystemEventsLauncher: SystemEventsLaunching {
  private var count = 0
  private let result: Bool

  init(result: Bool = true) {
    self.result = result
  }

  func ensureRunning() async -> Bool {
    count += 1
    return result
  }

  var invocationCount: Int {
    count
  }
}

final class TestScreenCaptureProcessRunner: ScreenCaptureProcessRunning, @unchecked Sendable {
  private let lock = NSLock()
  private var arguments: [[String]] = []
  private let result: Result<Void, ScreenCaptureProcessFailure>

  init(result: Result<Void, ScreenCaptureProcessFailure> = .success(())) {
    self.result = result
  }

  func run(arguments: [String]) async -> Result<Void, ScreenCaptureProcessFailure> {
    lock.withLock {
      self.arguments.append(arguments)
    }
    return result
  }

  var receivedArguments: [[String]] {
    lock.withLock {
      arguments
    }
  }
}

struct TestScreenCaptureAccessChecker: ScreenCaptureAccessChecking {
  let result: Bool

  init(result: Bool = true) {
    self.result = result
  }

  func hasAccess() -> Bool {
    result
  }
}
